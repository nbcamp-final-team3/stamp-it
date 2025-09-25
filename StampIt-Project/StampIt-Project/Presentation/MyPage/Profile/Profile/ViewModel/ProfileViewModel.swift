//
//  ProfileViewModel.swift
//  StampIt-Project
//
//  Created by kingj on 6/24/25.
//

import Foundation
import RxSwift
import RxRelay

final class ProfileViewModel: ViewModelProtocol {
    
    // MARK: - Dependency
    
    private let myPageUseCase: MyPageUseCaseProtocol
    private let accountManageUseCase: AccountManageUseCaseProtocol
    
    // MARK: - Action & State
    
    enum Action {
        case viewDidLoad
        case logoutButtonTapped
        case deleteAccountButtonTapped
        case leaveGroupButtonTapped
    }
    
    struct State {
        let user = BehaviorRelay<User?>(value: nil)
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
        myPageUseCase: MyPageUseCaseProtocol,
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
                case .logoutButtonTapped:
                    owner.showLogoutConfirmation()
                case .deleteAccountButtonTapped:
                    owner.showDeleteAccountConfirmation()
                case .leaveGroupButtonTapped:
                    owner.checkGroupMemberCountAndShowAlert()
                }
            }.disposed(by: disposeBag)
    }
    
    private func bindUser() {
        myPageUseCase.fetchUser()
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, user in
                owner.state.user.accept(user)
            }.disposed(by: disposeBag)
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
            state.alertMessage.accept("리더는 다른 멤버에게 리더 위임 후\n그룹 탈퇴가 가능합니다.")
        } else {
            state.shouldShowConfirmAlert.accept((
                "'\(currentUser.groupName)' 그룹에서 탈퇴하시겠어요?",
                "탈퇴 후 복구는 불가능하며 그룹에서\n생성된 스티커와 미션이 모두 삭제됩니다.",
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
                    self?.state.alertMessage.accept("그룹 탈퇴에 실패했습니다.")
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
