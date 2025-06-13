//
//  ReceiveInviteViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/9/25.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseFirestore
import FirebaseAuth

/// 그룹 초대 코드 입력 화면 viewModel
final class ReceiveInviteViewModel: ViewModelProtocol {

    // MARK: - Action & State

    enum Action {
        case codeChanged(String)
        case enterButtonTapped
    }

    struct State {
        let inviteCode = BehaviorRelay<String>(value: "")
        let isEnterButtonEnabled = BehaviorRelay<Bool>(value: false)
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()

    // MARK: - Init
    init() {
        bindActions()
    }

    // MARK: - Bind

    private func bindActions() {
        action
            .subscribe(onNext: { [weak self] action in
                switch action {
                case .codeChanged(let code):
                    self?.state.inviteCode.accept(code)
                    self?.state.isEnterButtonEnabled.accept(!code.isEmpty)
                case .enterButtonTapped:
                    // 미완 입장 처리 로직 필요
                    print("입장하기 버튼 눌림. 코드: \(self?.state.inviteCode.value ?? "")")
                }
            })
            .disposed(by: disposeBag)
    }
}
