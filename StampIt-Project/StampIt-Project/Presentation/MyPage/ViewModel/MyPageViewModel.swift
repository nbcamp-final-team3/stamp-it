//
//  MyPageViewModel.swift
//  StampIt-Project
//
//  Created by kingj on 6/11/25.
//

import Foundation
import RxSwift
import RxRelay

final class MyPageViewModel: ViewModelProtocol {
    
    // MARK: - Dependency
    
    private let myPageUseCase: MyPageUseCase
    private let accountManageUseCase: AccountManageUseCaseProtocol
    
    // MARK: - Action & State
    
    enum Action {
        case viewDidLoad
        case tabButtonTapped(TabType)
        case logoutButtonTapped
        case deleteAccountButtonTapped
        case leaveGroupButtonTapped
    }
    
    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let stickers = BehaviorRelay<[Sticker]>(value: [])
        let tabType = BehaviorRelay<TabType>(value: .stampBoard)
        let stickerSummary = BehaviorRelay<(collectedSticker: Int, completedBoard: Int)>(value: (.zero, .zero))
        let isLoading = BehaviorRelay<Bool>(value: false)
        let alertMessage = PublishRelay<String>()
        let shouldNavigateToLogin = PublishRelay<Void>()
        let shouldShowConfirmAlert = PublishRelay<(String, String, () -> Void)>() // (title, message, action)
        let toastMessage = PublishRelay<String>()
    }
    
    // MARK: - Properties
    
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    
    
    // MARK: - Initializer, Deinit, requiered
    
    init(
        myPageUseCase: MyPageUseCase,
        accountManageUseCase: AccountManageUseCaseProtocol
    ) {
        self.myPageUseCase = myPageUseCase
        self.accountManageUseCase = accountManageUseCase
        bindAction()
    }
    
    // MARK: - Bind
    
    private func bindAction() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .viewDidLoad:
                    owner.bindUser()
                case .tabButtonTapped(let type):
                    owner.state.tabType.accept(type)
                case .logoutButtonTapped:
                    owner.showLogoutConfirmation()
                case .deleteAccountButtonTapped:
                    owner.showDeleteAccountConfirmation()
                case .leaveGroupButtonTapped:
                    owner.checkGroupMemberCountAndShowAlert() // 💡 변경: 미리 멤버 수 체크
                }
            }.disposed(by: disposeBag)
    }
    
    private func bindUser() {
        myPageUseCase.fetchUser()
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, user in
                owner.state.user.accept(user)
                owner.bindStickerSummaryData()
            }.disposed(by: disposeBag)
    }
    
    private func fetchStickersByPin(userId: String, pinNumber: Int) {
        myPageUseCase.fetchStickersByPin(userId: userId, pinNumber: pinNumber)
            .subscribe(
                with: self,
                onNext: { owner, stickers in
                    owner.state.stickers.accept(
                        owner.makeZigzagOrder(from: stickers, columns: StampBoardSection.defaultBoard.column)
                    )
                }, onError: { owner, error in
                    owner.state.stickers.accept(
                        owner.makeZigzagOrder(from: [], columns: StampBoardSection.defaultBoard.column)
                    )
                }
            ).disposed(by: disposeBag)
    }
    
    private func bindStickerSummaryData() {
        guard let user = state.user.value else { return }
        
        myPageUseCase.fetchStickerCount(userId: user.userID)
            .subscribe(with: self) { owner, sticker in
                let totalSticker = StampBoardSection.defaultBoard.totalStamp
                let collectedSticker = Int(sticker % totalSticker)
                let completedBoard = Int(sticker / totalSticker)
                
                owner.state.stickerSummary.accept((
                    collectedSticker: collectedSticker,
                    completedBoard: completedBoard
                ))
                
                owner.fetchStickersByPin(
                    userId: user.userID,
                    pinNumber: completedBoard + 1
                )
            }.disposed(by: disposeBag)
    }
    
    private func makeZigzagOrder(from stickers: [Sticker], columns: Int) -> [Sticker] {
        let totalStickerCount = StampBoardSection.defaultBoard.totalStamp
        let totalStickers: [Sticker] = {
            (0..<totalStickerCount).map { index in
                if stickers.count == .zero {
                    return Sticker(userID: "", stickerID: "\(UUID())", title: "", description: "", imageURL: "", type: .stampGray, createdAt: Date(), maxStickers: 30, pinNumber: 1, assignedBy: "")
                } else {
                    if index < stickers.count {
                        return stickers[index]
                    } else {
                        return Sticker(userID: "", stickerID: "\(UUID())", title: "", description: "", imageURL: "", type: .stampGray, createdAt: Date(), maxStickers: 30, pinNumber: 1, assignedBy: "")
                    }
                }
            }
        }()
        
        let rows = stride(from: 0, to: totalStickers.count, by: columns)
            .map {
                Array(totalStickers[$0..<min($0 + columns, totalStickers.count)])
            }
        
        let ordered = rows.enumerated().flatMap { (index, row) in
            index.isMultiple(of: 2) ? row : row.reversed()
        }
        return ordered
    }
    
    // MARK: - 계정 관리 메서드 (완전 분리된 로직)
    
    /// 로그아웃 확인 - 독립적 처리
    private func showLogoutConfirmation() {
        state.shouldShowConfirmAlert.accept((
            "정말 로그아웃 하시겠어요?",
            "현재까지의 모든 데이터는\n재로그인할 때까지 안전하게 보관돼요.",
            { [weak self] in
                self?.performLogout()
            }
        ))
    }
    
    /// 서비스 탈퇴 확인 - 그룹 탈퇴와 완전 분리
    private func showDeleteAccountConfirmation() {
        // 💡 핵심: 서비스 탈퇴는 바로 확인 다이얼로그 (리더 체크 안함)
        state.shouldShowConfirmAlert.accept((
            "'스탬프잇'을 탈퇴하시겠어요?",
            "계정과 모든 데이터가 완전히 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.",
            { [weak self] in
                self?.performDeleteAccount()
            }
        ))
    }
    
    // MARK: - 그룹 멤버 수 미리 체크
    /// 그룹 탈퇴 버튼 클릭 시 멤버 수 먼저 체크
    private func checkGroupMemberCountAndShowAlert() {
        guard let currentUser = state.user.value else {
            state.alertMessage.accept("사용자 정보를 찾을 수 없습니다.")
            return
        }
        
        // 그룹 멤버 수를 미리 확인
        accountManageUseCase.getGroupMemberCount(groupId: currentUser.groupID)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] memberCount in
                    if memberCount <= 1 {
                        // 1인 그룹: 바로 에러 Alert 표시
                        self?.state.alertMessage.accept("1인 그룹은 그룹 탈퇴가 불가합니다")
                    } else {
                        // 다인 그룹: 확인 Alert 표시
                        self?.showLeaveGroupConfirmation(for: currentUser)
                    }
                },
                onError: { [weak self] error in
                    self?.state.alertMessage.accept("그룹 정보를 확인할 수 없습니다.")
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// 그룹 탈퇴 확인 - 다인 그룹에서만 호출됨
    private func showLeaveGroupConfirmation(for currentUser: User) {
        if currentUser.isLeader {
            state.shouldShowConfirmAlert.accept((
                "리더 권한을 위임하고 탈퇴하시겠어요?",
                "가장 오래된 멤버가 새 리더가 되며,\n탈퇴 후 복구는 불가능합니다.",
                { [weak self] in
                    self?.performLeaveGroup()
                }
            ))
        } else {
            state.shouldShowConfirmAlert.accept((
                "'\(currentUser.groupName)' 그룹에서 탈퇴하시겠어요?",
                "탈퇴 후 복구는 불가능해요",
                { [weak self] in
                    self?.performLeaveGroup()
                }
            ))
        }
    }
    
    /// 로그아웃 실행
    private func performLogout() {
        state.isLoading.accept(true)
        
        accountManageUseCase.signOut()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    self?.state.isLoading.accept(false)
                    self?.handleLogoutSuccess()
                },
                onError: { [weak self] error in
                    self?.state.isLoading.accept(false)
                    self?.state.alertMessage.accept("로그아웃에 실패했습니다.")
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// 서비스 탈퇴 실행
    private func performDeleteAccount() {
        guard state.user.value != nil else {
            state.alertMessage.accept("사용자 정보를 찾을 수 없습니다.")
            return
        }
                
        state.isLoading.accept(true)
        
        accountManageUseCase.deleteAccount()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    self?.handleDeleteAccountSuccess()
                },
                onError: { [weak self] error in
                    self?.state.isLoading.accept(false)
                    
                    // 서비스 탈퇴 전용 에러 처리 - Repository 메시지 그대로 사용
                    if let repositoryError = error as? RepositoryError {
                        switch repositoryError {
                        case .dataError(let message):
                            //  Repository에서 온 메시지를 그대로 표시
                            self?.state.alertMessage.accept(message)
                        default:
                            self?.state.alertMessage.accept("계정 탈퇴 중 오류가 발생했습니다.")
                        }
                    } else {
                        self?.state.alertMessage.accept("계정 탈퇴 중 오류가 발생했습니다.")
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// 그룹 탈퇴 실행 - 다인 그룹에서만 실행됨
    private func performLeaveGroup() {
        state.isLoading.accept(true)
        
        accountManageUseCase.leaveGroup()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] updatedUser in
                    self?.state.isLoading.accept(false)
                    self?.state.user.accept(updatedUser)
                    self?.state.toastMessage.accept("그룹에서 성공적으로 탈퇴했어요.")
                },
                onError: { [weak self] error in
                    self?.state.isLoading.accept(false)
                    
                    // 그룹 탈퇴 전용 에러 처리 - Repository 메시지 그대로 사용
                    if let repositoryError = error as? RepositoryError {
                        switch repositoryError {
                        case .dataError(let message):
                            // Repository에서 온 메시지를 그대로 표시
                            self?.state.alertMessage.accept(message)
                        default:
                            self?.state.alertMessage.accept("다른 멤버에게 리더 위임 후\n그룹 탈퇴가 가능합니다.")
                        }
                    } else {
                        self?.state.alertMessage.accept("그룹 탈퇴에 실패했습니다.")
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helper Methods
    
    /// 로그아웃 성공 처리
    private func handleLogoutSuccess() {
        UserCache.shared.clearCache()
        state.toastMessage.accept("로그아웃 되었습니다.")
        state.shouldNavigateToLogin.accept(())
    }
    
    /// 계정 탈퇴 성공 처리
    private func handleDeleteAccountSuccess() {
        UserCache.shared.clearCache()
        
        // 기타 사용자 관련 UserDefaults 삭제
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "lastLoginDate")
        UserDefaults.standard.synchronize()
        state.toastMessage.accept("계정이 성공적으로 삭제되었습니다.")
        state.shouldNavigateToLogin.accept(())
    }
}
