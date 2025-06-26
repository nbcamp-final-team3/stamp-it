//
//  MemberManageOptionViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/25/25.
//

import Foundation
import RxSwift
import RxRelay

final class MemberManageOptionViewModel: ViewModelProtocol {

    // MARK: - Action & State

    enum Action {
        case didTapOptionCard(MemberManageOptionType)
        case didTapConfirmButton
    }

    struct State {
        let selectedOption = BehaviorRelay<MemberManageOptionType?>(value: nil)
        let isEnabledConfirmButton = PublishRelay<Bool>()
        let dismiss = PublishRelay<MemberManageOptionType>()
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    
    private let memberNickname: String

    // MARK: - Init

    init(memberNickname: String) {
        self.memberNickname = memberNickname
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
                    owner.confirmAction()
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Methods

    private func toggleSelection(_ type: MemberManageOptionType) {
        let current = state.selectedOption.value
        let new: MemberManageOptionType? = current == type ? nil : type
        state.selectedOption.accept(new)
        isEnabledConfirm()
    }

    private func isEnabledConfirm() {
        let isEnabled = state.selectedOption.value != nil
        state.isEnabledConfirmButton.accept(isEnabled)
    }
    
    func confirmAction() {
        guard let selectedType = state.selectedOption.value else { return }
        state.dismiss.accept(selectedType)
    }
    
    func getMemberNickname() -> String {
        return memberNickname
    }
}

