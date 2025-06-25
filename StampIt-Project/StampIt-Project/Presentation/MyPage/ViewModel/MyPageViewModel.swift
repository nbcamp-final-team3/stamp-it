//
//  MyPageViewModel.swift
//  StampIt-Project
//
//  Created by kingj on 6/11/25.
//

import Foundation
import RxSwift
import RxRelay

final class MyPageViewModel: ViewModelProtocol {
    
    // MARK: - Action & State
    
    enum Action {
        case tabChanged(TabType)
    }
    
    struct State {
        let tabType = BehaviorRelay<TabType>(value: .stampBoard)
    }
    
    // MARK: - Properties
    
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    
    // MARK: - Initializer, Deinit, requiered
    
    init() {
        bindAction()
    }
    
    // MARK: - Bind
    
    private func bindAction() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .tabChanged(let type):
                    owner.state.tabType.accept(type)
                }
            }.disposed(by: disposeBag)
    }
                    self?.state.alertMessage.accept("로그아웃에 실패했습니다.")
                }
}
