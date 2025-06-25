//
//  MemberDeleteViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/15/25.
//

import Foundation
import RxSwift
import RxCocoa


final class GroupMemberManageViewModel: ViewModelProtocol {

    // MARK: - Action & State

    enum Action {
        case exportButtonTapped
        case didTapCardOptionButton
        case didReceiveMemberManageType(MemberManageOptionType)
    }

    struct State {
        let isLeader = BehaviorRelay<Bool>(value: false)
        let isLeaderMandate = PublishRelay<Void>()
        let isMemberExport = PublishRelay<Void>()
        let showOptionSheet = PublishRelay<Void>()
    }

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()

    init() {
        bindActions()
    }

    private func bindActions() {
        // Action과 State 바인딩 구현
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .didTapCardOptionButton:
                    owner.state.showOptionSheet.accept(())
                case .didReceiveMemberManageType(let type):
                    owner.handleMemberState(type: type)
                case .exportButtonTapped:
                    owner.handleManageOption()
                }
            }.disposed(by: disposeBag)
    }

    private func handleManageOption() {
        state.showOptionSheet.accept(())
    }

    private func handleMemberState(type: MemberManageOptionType) {
        switch type {
        case .leaderMandate:
            state.isLeaderMandate.accept(())
        case .exportMember:
            state.isMemberExport.accept(())
        }
    }
}


extension GroupMemberManageViewModel {
    enum Section {
        case main
    }

    struct Item: Hashable {
        let id: String
        let name: String
        // ...
    }
}
