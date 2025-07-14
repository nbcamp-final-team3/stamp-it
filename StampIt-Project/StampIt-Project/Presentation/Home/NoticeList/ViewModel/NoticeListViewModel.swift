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

    // MARK: - Action & State

    enum Action {
    }

    struct State {
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
                }
            }
            .disposed(by: disposeBag)
    }
}
