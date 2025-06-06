//
//  HomeViewModel.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation
import RxSwift
import RxRelay

final class HomeViewModel: ViewModelProtocol {
    // MARK: - Dependency
    private let useCase: HomeUseCase

    // MARK: - Action & State
    enum Action {
        case viewDidLoad
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
    }

    // MARK: - Properties
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()

    // MARK: - Init
    init(useCase: HomeUseCase) {
        self.useCase = useCase
        bind()
    }

    // MARK: - Bind
    private func bind() {
        bindUser()
    private func bindUser() {
        action
            .filter { $0 == .viewDidLoad }
            .flatMap { _ in self.useCase.fetchUser() }
            .bind(to: state.user)
            .disposed(by: disposeBag)
    }
            .disposed(by: disposeBag)
    }
}
