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

    }

    struct State {
        let inviteCode = BehaviorRelay<String>(value: "")
        let currentUser = BehaviorRelay<User?>(value: nil)
        let showMessage = PublishRelay<(ToastType, String)>()

    }

    // MARK: - Properties
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()
    private let useCase: InviteUseCase

    // MARK: - Init
    init(useCase: InviteUseCase) {
        self.useCase = useCase
        showInviteCode()
    }

    // MARK: - Private Methods

    // 화면에 접속했을 때 초대 코드를 보여주는 메서드
    private func showInviteCode() {
        useCase.getInviteCodeAndUserInfo()
            .subscribe(onNext: { [weak self] (code, user) in
                self?.state.inviteCode.accept(code)
                self?.state.currentUser.accept(user)
            }, onError: { [weak self] error in
                let message: String

                if let repoError = error as? RepositoryError {
                    message = repoError.localizedDescription
                } else {
                    message = "초대 코드를 불러오지 못했습니다."
                }

                self?.state.showMessage.accept((.failure, message))
            })
            .disposed(by: disposeBag)
    }

}
