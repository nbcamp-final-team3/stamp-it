//
//  MemberDeleteViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/15/25.
//

import Foundation
import RxSwift
import RxCocoa


final class MemberDeleteViewModel: ViewModelProtocol {

    // MARK: - Action & State

    enum Action {
        case exportButtonTapped
    }

    struct State {
        // 접속해 있는 유저가 그룹의 리더인지 여부
        let isLeader = BehaviorRelay<Bool>(value: false)
    }

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()

    init() {
        bindActions()
    }

    private func bindActions() {
        // Action과 State 바인딩 구현
    }
}


extension MemberDeleteViewModel {
    enum Section {
        case main
    }

    struct Item: Hashable {
        let id: String
        let name: String
        // ...
    }
}
