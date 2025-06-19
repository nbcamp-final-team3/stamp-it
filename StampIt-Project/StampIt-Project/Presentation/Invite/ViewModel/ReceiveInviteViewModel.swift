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
    }

    struct State {
        let inviteCode = BehaviorRelay<String>(value: "")
        let isEnterButtonEnabled = BehaviorRelay<Bool>(value: false)
        let showMessage = PublishRelay<String>()
        let didCompleteInvite = PublishRelay<Void>()
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()

    private let useCase: InviteUseCase

    // MARK: - Init

    init(useCase: InviteUseCase) {
        self.useCase = useCase
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
                    self.handleEnterButtonTapped()
                }
            })
            .disposed(by: disposeBag)
    }

    private func handleEnterButtonTapped() {
        let code = state.inviteCode.value

        useCase.acceptInvite(inviteCode: code)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] invite in
                self?.state.showMessage.accept("초대 완료!")
                // MAKR: - 초대 완료가 됐을때 VC에 발행
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.state.didCompleteInvite.accept(())
                }
            }, onError: { [weak self] error in
                print("[DEBUG] error:", error)
                print("[DEBUG] error type:", type(of: error))
                let message: String

                

                if let repoError = error as? RepositoryError {
                    message = repoError.localizedDescription
                } else {
                    message = "코드를 재확인 해주세요."
                }

                self?.state.showMessage.accept(message)
            })
            .disposed(by: disposeBag)
    }
}
