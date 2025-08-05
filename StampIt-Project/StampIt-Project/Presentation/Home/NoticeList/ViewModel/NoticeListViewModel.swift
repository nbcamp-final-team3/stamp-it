//
//  NoticeListViewModel.swift
//  StampIt-Project
//
//  Created by daeun on 7/9/25.
//

import Foundation
import RxSwift
import RxRelay

final class NoticeListViewModel: ViewModelProtocol {
    // MARK: - Dependency

    let useCase: NoticeUseCaseProtocol!

    // MARK: - Action & State

    enum Action {
        case navigateBack
    }

    struct State {
        var isNavigateBack = PublishRelay<Void>()
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()

    // MARK: - Init

    init(useCase: NoticeUseCaseProtocol) {
        self.useCase = useCase
        bind()
    }

    // MARK: - Bind

    private func bind() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .navigateBack:
                    owner.state.isNavigateBack.accept(())
                }
            }
            .disposed(by: disposeBag)
    }
}
