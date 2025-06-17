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
    
    init(myPageUseCase: MyPageUseCase, accountManageUseCase: AccountManageUseCaseProtocol) {
        self.myPageUseCase = myPageUseCase
        self.accountManageUseCase = accountManageUseCase
        
        bind()
    }
    
    // MARK: - Bind
    
    private func bind() {
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
                self.state.user.accept(user)
                owner.bindSticker()
            }.disposed(by: disposeBag)
    }
    
    private func bindSticker() {
        // TODO: Sticker 엔티티 수정완료시 변경
        //        guard let user = state.user.value else {
        //            self.state.stickers.accept(
        //                makeZigzagOrder(
        //                    from: self.state.stickers.value,
        //                    columns: MyPage.StampBoard.column
        //                )
        //            )
        //            return
        //        }
        myPageUseCase.fetchStickers(userId: "testUser001")
        //        myPageUseCase.fetchStickers(userId: user.userID)
            .subscribe(
                with: self,
                onNext: { owner, stickers in
                    print("STICKER: \n\(stickers)")
                    self.state.stickers.accept(
                        self.makeZigzagOrder(from: stickers, columns: MyPage.StampBoard.column)
                    )
                }, onError: { owner, error in
                    print("BIND ERROR: \(error.localizedDescription)")
                }
            ).disposed(by: disposeBag)
    }
    
    private func makeZigzagOrder(from stickers: [Sticker], columns: Int) -> [Sticker] {
        let totalStickers: [Sticker] = (0..<MyPage.StampBoard.totalStampNumber).map { index in
            if index < stickers.count {
                return stickers[index]
            } else {
                return Sticker(stickerID: "\(UUID())", title: "", description: "", imageURL: "", type: .stampGray, createdAt: Date())
            }
        }
        
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
            "로그아웃",
            "정말 로그아웃 하시겠습니까?",
            { [weak self] in
                self?.performLogout()
            }
        ))
    }
    
    private func showDeleteAccountConfirmation() {
        state.shouldShowConfirmAlert.accept((
            "계정 탈퇴",
            "계정을 탈퇴하면 모든 데이터가 삭제됩니다.\n정말 탈퇴하시겠습니까?",
            { [weak self] in
                self?.performDeleteAccount()
            }
        ))
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

    /// 그룹 멤버 수에 따른 처리
    private func handleGroupMemberCount(memberCount: Int, groupName: String) {
        if memberCount <= 1 {
            // 본인만 있는 경우 탈퇴 불가
            state.alertMessage.accept("혼자 있는 그룹에서는 탈퇴할 수 없습니다.\n계정 탈퇴를 원하시면 '서비스 탈퇴'를 이용해주세요.")
        } else {
            // 다른 멤버가 있는 경우 탈퇴 가능
            state.shouldShowConfirmAlert.accept((
                "그룹 탈퇴",
                "\(groupName)에서 탈퇴하고 새로운 그룹을 만드시겠습니까?\n\n현재 그룹 멤버: \(memberCount)명",
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
    
    /// 계정 탈퇴 실행
    private func performDeleteAccount() {
        state.isLoading.accept(true)
        
        accountManageUseCase.deleteAccount()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    self?.state.isLoading.accept(false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.state.alertMessage.accept("계정이 완전히 삭제되었습니다.")
                    }
                    self?.handleDeleteAccountSuccess()
                },
                onError: { [weak self] error in
                    self?.state.isLoading.accept(false)
                    self?.state.alertMessage.accept("계정 탈퇴에 실패했습니다.")
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
                        self?.state.alertMessage.accept("기존 그룹 탈퇴 후 새로운 그룹 '\(updatedUser.groupName)'이 생성되었습니다.")
                    }
                },
                onError: { [weak self] error in
                    self?.state.isLoading.accept(false)
                    self?.state.alertMessage.accept("그룹 탈퇴에 실패했습니다.")
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
