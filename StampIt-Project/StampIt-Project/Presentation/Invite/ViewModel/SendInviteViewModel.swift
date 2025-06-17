//
//  SendInviteViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/7/25.
//

import Foundation
import RxSwift
import RxCocoa

final class SendInviteViewModel: ViewModelProtocol {
    // MARK: - Action & State
    enum Action {
        case copyButtonTapped
    }

    struct State {
        let inviteCode = BehaviorRelay<String>(value: "복사 버튼을 클릭해주세요.")
        let showMessage = PublishRelay<String>()
    }

    // MARK: - Properties
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()
    private let useCase: InviteUseCase

    // MARK: - Init
    init(useCase: InviteUseCase) {
        self.useCase = useCase
        bindActions()
    }

    // MARK: - Bind
    private func bindActions() {
        action
            .subscribe(onNext: { [weak self] action in
                guard let self = self else { return }
                
                switch action {
                case .copyButtonTapped:
                    self.copyInviteCode()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    private func copyInviteCode() {
        useCase.sequenceCreateCode()
            .subscribe(onNext: { [weak self] code in
                guard let self = self else { return }
                self.state.inviteCode.accept(code)
                self.state.showMessage.accept("초대 코드가 복사되었습니다")
            }, onError: { [weak self] error in
                self?.state.showMessage.accept("초대 코드 생성에 실패했습니다.")
            })
            .disposed(by: disposeBag)
    }

}
