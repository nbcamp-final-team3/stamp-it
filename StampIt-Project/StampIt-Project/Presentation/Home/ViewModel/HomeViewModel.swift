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
