//
//  MyMissionViewModel.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation
import RxSwift
import RxRelay

final class MyMissionViewModel {
    // MARK: - Dependency

    private let useCase: MyMissionUseCaseProtocol

    // MARK: - Action & State

    enum Action {
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()

    // MARK: - Init

    init(user: User, useCase: MyMissionUseCaseProtocol) {
        self.useCase = useCase
        state.user.accept(user)
        bind()
    }

    // MARK: - Bind

    private func bind() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Methods
}
