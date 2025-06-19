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
                    owner.showLeaveGroupConfirmation()
                }
            }.disposed(by: disposeBag)
    }
    
    private func bindUser() {
        myPageUseCase.fetchUser()
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
    
    // MARK: - 계정 관리 메서드 추가
    private func showLogoutConfirmation() {
        state.shouldShowConfirmAlert.accept((
            "정말 로그아웃 하시겠어요?",
            "현재까지의 모든 데이터는\n재로그인할 때까지 안전하게 보관돼요.",
            { [weak self] in
                self?.performLogout()
            }
        ))
    }
    
    private func showDeleteAccountConfirmation() {
        guard let currentUser = state.user.value else { return }
        
        if currentUser.isLeader {
            state.shouldShowConfirmAlert.accept((
                "'스탬프잇'을 탈퇴하시겠어요?",
                "리더님이 탈퇴하면 가장 오래된 멤버가\n자동으로 새 리더가 됩니다.",
                { [weak self] in
                    self?.performDeleteAccount()
                }
            ))
        } else {
            state.shouldShowConfirmAlert.accept((
                "'스탬프잇'을 탈퇴하시겠어요?",
                "계정을 탈퇴하면 그룹도 자동으로 탈퇴돼요.\n재가입은 언제나 환영이에요!",
                { [weak self] in
                    self?.performDeleteAccount()
                }
            ))
        }
    }
    
    /// 그룹 탈퇴 확인 다이얼로그 표시 전 멤버 수 체크
    private func showLeaveGroupConfirmation() {
        checkGroupMemberCountBeforeLeaving()
    }

    /// 그룹 멤버 수 확인 후 탈퇴 가능 여부 판단
    private func checkGroupMemberCountBeforeLeaving() {
        guard let currentUser = state.user.value else {
            state.alertMessage.accept("사용자 정보를 찾을 수 없습니다.")
            return
        }
        
        state.isLoading.accept(true)
        
        accountManageUseCase.getGroupMemberCount(groupId: currentUser.groupID)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] memberCount in
                    self?.state.isLoading.accept(false)
                    self?.handleGroupMemberCount(memberCount: memberCount, groupName: currentUser.groupName)
                },
                onError: { [weak self] error in
                    self?.state.isLoading.accept(false)
                    self?.state.alertMessage.accept("그룹 정보를 확인할 수 없습니다.")
                }
            )
            .disposed(by: disposeBag)
    }

    /// 그룹 멤버 수에 따른 처리 (그룹탈퇴)
    private func handleGroupMemberCount(memberCount: Int, groupName: String) {
        guard let currentUser = state.user.value else { return }

        if memberCount <= 1 {
            // 본인만 있는 경우: 탈퇴 불가
            state.alertMessage.accept("혼자 있는 그룹에서는 탈퇴할 수 없습니다.\n계정 탈퇴를 원하시면 '서비스 탈퇴'를 이용해주세요.")
        }else if currentUser.isLeader {
                // 리더도 탈퇴 가능하되, 자동 위임 안내
                state.shouldShowConfirmAlert.accept((
                    "리더 권한을 위임하고 탈퇴하시겠어요?",
                    "가장 오래된 멤버가 새 리더가 되며,\n탈퇴 후 복구는 불가능합니다.",
                    { [weak self] in
                        self?.performLeaderLeaveGroup()
                    }
                ))
            } else {
            // 다른 멤버가 있는 경우 탈퇴 가능
            state.shouldShowConfirmAlert.accept((
                "'\(groupName)' 그룹에서 탈퇴하시겠어요?",
                "탈퇴 후 복구는 불가능해요",
                { [weak self] in
                    self?.performLeaveGroup()
                }
            ))
        }
    }
    
    /// 리더 탈퇴 불가 안내 (향후 수정 예정)
    /*
    private func showLeaderCannotLeaveAlert(groupName: String) {
        // showLeaderOptionsAlert() 호출로 변경 예정
        
        let message = """
        그룹장은 직접 탈퇴할 수 없습니다.
        
        다음 중 하나를 선택해주세요:
        1️⃣ 다른 멤버에게 그룹장 위임하기
        2️⃣ 모든 멤버 내보내기 후 계정 탈퇴
        3️⃣ 계정 탈퇴 (그룹 완전 삭제)
        """
        
        state.alertMessage.accept(message)
    }
     */

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
    
    /// 계정 탈퇴 실행
    private func performDeleteAccount() {
        guard let currentUser = state.user.value else {
            state.alertMessage.accept("사용자 정보를 불러올 수 없습니다.")
            return
        }
        
        state.isLoading.accept(true)
        
        // 🔥 그룹 멤버 수 확인 후 바로 분기 처리
        accountManageUseCase.getGroupMemberCount(groupId: currentUser.groupID)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] memberCount in
                    if memberCount == 1 {
                        // 1인 그룹 → 바로 삭제
                        self?.executeDeleteAccount()
                    } else if currentUser.isLeader {
                        // 리더 + 다인 그룹 → 자동 리더 위임 후 삭제
                        self?.executeDeleteAccount()
                    } else {
                        // 일반 멤버 + 다인 그룹 → 바로 삭제
                        self?.executeDeleteAccount()
                    }
                },
                onError: { [weak self] error in
                    // 멤버 수 조회 실패 시 1인으로 처리해서 바로 삭제
                    self?.executeDeleteAccount()
                }
            )
            .disposed(by: disposeBag)
    }

    // 실제 삭제 실행
    private func executeDeleteAccount() {
        accountManageUseCase.deleteAccount()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    self?.handleDeleteAccountSuccess()
                },
                onError: { [weak self] error in
                    self?.state.isLoading.accept(false)
                    if let repoError = error as? RepositoryError,
                       case .userNotFound = repoError {
                        self?.handleDeleteAccountSuccess()
                    } else {
                        self?.state.alertMessage.accept("계정 탈퇴에 실패했습니다.")
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// 그룹 탈퇴 실행
    private func performLeaveGroup() {
        state.isLoading.accept(true)
        
        accountManageUseCase.leaveGroup()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] updatedUser in
                    self?.state.isLoading.accept(false)
                    self?.state.user.accept(updatedUser)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.state.alertMessage.accept("기존 그룹 탈퇴가 완료되었습니다.")
                    }
                },
                onError: { [weak self] error in
                    self?.state.isLoading.accept(false)
                    self?.state.alertMessage.accept("그룹 탈퇴에 실패했습니다.")
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// 리더 그룹 탈퇴 실행 (자동 위임 포함)
    private func performLeaderLeaveGroup() {
        state.isLoading.accept(true)
        
        accountManageUseCase.leaveGroup()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] updatedUser in
                    self?.state.isLoading.accept(false)
                    self?.state.user.accept(updatedUser)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.state.alertMessage.accept("리더 권한이 위임되고 그룹 탈퇴가 완료되었습니다.")
                    }
                },
                onError: { [weak self] error in
                    self?.state.isLoading.accept(false)
                    self?.state.alertMessage.accept("리더 위임 및 그룹 탈퇴에 실패했습니다.")
                }
            )
            .disposed(by: disposeBag)
    }
    
    // MARK: - Helper Methods
    
    /// 로그아웃 성공 처리
    private func handleLogoutSuccess() {
        UserCache.shared.clearCache()
        state.shouldNavigateToLogin.accept(())
        
        // TODO: UserDefaults에서 로그인 관련 정보 삭제 (미래 기능 대비: 생체 인증 등)
        // UserDefaults.standard.removeObject(forKey: "userToken")
        // UserDefaults.standard.removeObject(forKey: "lastLoginDate")
        // UserDefaults.standard.removeObject(forKey: "autoLoginEnabled")
        // UserDefaults.standard.removeObject(forKey: "biometricLoginEnabled")
        // UserDefaults.standard.synchronize()

        print("🔄 로그아웃 완료 - 사용자 데이터 삭제 및 로그인 화면 이동")
    }
    
    /// 계정 탈퇴 성공 처리
    private func handleDeleteAccountSuccess() {
        UserCache.shared.clearCache()
        
        // 기타 사용자 관련 UserDefaults 삭제
        UserDefaults.standard.removeObject(forKey: "userToken")
        UserDefaults.standard.removeObject(forKey: "lastLoginDate")
        UserDefaults.standard.synchronize()
        
        state.shouldNavigateToLogin.accept(())
        print("🗑️ 계정 탈퇴 완료 - 모든 사용자 데이터 삭제 및 로그인 화면 이동")
    }
}
