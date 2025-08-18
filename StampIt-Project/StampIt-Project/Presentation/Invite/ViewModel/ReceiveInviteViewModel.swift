//
//  ReceiveInviteViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/9/25.
//

import Foundation
import RxSwift
import RxCocoa

/// 그룹 초대 코드 입력 화면 viewModel
/// 그룹 참여 실패 했을 때 토스트 메세지로 실패 여부 알림
final class ReceiveInviteViewModel: ViewModelProtocol {

    // MARK: - Action & State

    enum Action {
        case codeChanged(String)
        case enterButtonTapped
        case confirmGroupExit
        case cancelGroupExit
    }

    struct State {
        let inviteCode = BehaviorRelay<String>(value: "")
        let isEnterButtonEnabled = BehaviorRelay<Bool>(value: false)
        let showMessage = PublishRelay<(ToastType, String)>()
        let didCompleteInvite = PublishRelay<Void>()
        let showGroupExitConfirmation = PublishRelay<String>() // 다인 그룹 탈퇴 확인 알림
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()

    private let useCase: InviteUseCase
    private let notificationUseCase: NotificationUseCase
    
    // 중복 실행 방지를 위한 플래그
    private var isProcessingInvite = false

    // MARK: - Init

    init(useCase: InviteUseCase, notificationUseCase: NotificationUseCase) {
        self.useCase = useCase
        self.notificationUseCase = notificationUseCase
        bindActions()
    }

    // MARK: - Bind

    private func bindActions() {
        action
            .subscribe(onNext: { [weak self] action in
                guard let self = self else { return }

                switch action {
                case .codeChanged(let code):
                    self.state.inviteCode.accept(code)
                    self.state.isEnterButtonEnabled.accept(!code.isEmpty)

                case .enterButtonTapped:
                    // 🎯 입장하기 버튼 클릭 시에만 다인 그룹 확인 로직 실행
                    self.handleEnterButtonTapped()
                    
                case .confirmGroupExit:
                    // ✅ 확인 알림에서 "입장하기" 클릭 시 실제 그룹 이동 실행
                    self.handleConfirmGroupExit()
                    
                case .cancelGroupExit:
                    // ❌ 취소 시 아무것도 하지 않음 (다시 입장하기 버튼 클릭 가능)
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    /// 🎯 입장하기 버튼 클릭 시 호출되는 메서드
    /// 다인 그룹인지 확인하여 분기 처리
    private func handleEnterButtonTapped() {
        // 중복 실행 방지
        guard !isProcessingInvite else { return }
        
        let code = state.inviteCode.value
        
        // 먼저 다인 그룹인지 확인
        useCase.checkIfConfirmationNeeded(inviteCode: code)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] needsConfirmation in
                guard let self = self else { return }
                
                if needsConfirmation {
                    // 🔍 다인 그룹인 경우 확인 알림 표시
                    self.state.showGroupExitConfirmation.accept(code)
                } else {
                    // 🚀 1인 그룹인 경우 바로 입장
                    self.processInviteAcceptance(code: code)
                }
            }, onError: { [weak self] error in
                self?.isProcessingInvite = false
                self?.handleError(error)
            })
            .disposed(by: disposeBag)
    }
    
    /// ✅ 확인 알림에서 "입장하기" 클릭 시 호출되는 메서드
    /// 실제 그룹 이동 로직 실행
    private func handleConfirmGroupExit() {
        // 중복 실행 방지
        guard !isProcessingInvite else { return }
        
        let code = state.inviteCode.value
        processInviteAcceptance(code: code)
    }
    
    /// 🚀 실제 그룹 입장 처리 메서드
    /// UseCase의 acceptInvite 호출하여 그룹 이동 실행
    private func processInviteAcceptance(code: String) {
    guard !isProcessingInvite else { return }
    isProcessingInvite = true
    
    useCase.acceptInvite(inviteCode: code)
        .flatMap { [weak self] userAndInvite -> Observable<Void> in
            guard let self = self else { return .empty() }
            
            let (user, invite) = userAndInvite
            
            // 🎯 NotificationUseCase를 통해 알림 전송
            return self.notificationUseCase.sendGroupJoinNotification(
                userId: user.userID,
                userNickname: user.nickname,
                toGroupId: invite.groupId
            )
        }
        .subscribe(onNext: { [weak self] _ in
            self?.isProcessingInvite = false
            self?.state.showMessage.accept((.success, "초대 완료!"))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self?.state.didCompleteInvite.accept(())
            }
        }, onError: { [weak self] error in
            self?.isProcessingInvite = false
            self?.handleError(error)
        })
        .disposed(by: disposeBag)
}
    
    private func handleError(_ error: Error) {
        print("[DEBUG] error:", error)
        print("[DEBUG] error type:", type(of: error))
        let message: String

        if let repoError = error as? RepositoryError {
            message = repoError.localizedDescription
        } else {
            message = "코드를 재확인 해주세요."
        }

        state.showMessage.accept((.failure, message))
    }
}
