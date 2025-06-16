//
//  ReceiveInviteViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/9/25.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseFirestore
import FirebaseAuth

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
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()

    private let useCase: ReceiveInviteUseCase
    private let repository: ReceiveInviteRepository

    // MARK: - Init

    init(receiveInviteUseCase: ReceiveInviteUseCase,
         receiveInviteRepository: ReceiveInviteRepository) {
        self.useCase = receiveInviteUseCase
        self.repository = receiveInviteRepository
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

        repository.fetchInvite(inviteCode: code)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] invite in
                self?.state.showMessage.accept("초대 완료! 그룹 ID: \(invite.groupId)")
            }, onError: { [weak self] error in
                self?.state.showMessage.accept("초대 실패: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
}
