//
//  SelectInvitationViewModel.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/10/25.
//

import Foundation
import RxSwift
import RxRelay

final class SelectInvitationViewModel: ViewModelProtocol {

    // MARK: - Action & State

    enum Action {
        case didTapOptionCard(InvitationType)
        case didTapConfirmButton
    }

    struct State {
        let selectedOption = BehaviorRelay<InvitationType?>(value: nil)
        let isEnabledConfirmButton = PublishRelay<Bool>()
        let dismiss = PublishRelay<InvitationType>()
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()

    // MARK: - Init

    init() {
        bind()
    }

    // MARK: - Bind

    private func bind() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .didTapOptionCard(let type):
                    owner.toggleSelection(type)
                case .didTapConfirmButton:
                    owner.dismissVC()
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Methods

    private func toggleSelection(_ type: InvitationType) {
        let current = state.selectedOption.value
        let new: InvitationType? = current == type ? nil : type
        state.selectedOption.accept(new)
        isEnabledConfirm()
    }

    private func isEnabledConfirm() {
        let isEnabled = state.selectedOption.value != nil
        state.isEnabledConfirmButton.accept(isEnabled)
    }

    private func dismissVC() {
        guard let selectedType = state.selectedOption.value else { return }
        state.dismiss.accept(selectedType)
    }
}
