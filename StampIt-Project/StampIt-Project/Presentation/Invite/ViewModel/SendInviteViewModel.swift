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
        let inviteCode = BehaviorRelay<String>(value: "")
        let showMessage = PublishRelay<String>()
        let copyToClipboard = PublishRelay<String>()

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
        showInviteCode()
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
    // 복사버튼을 눌렀을때 show 메세지와 UIPasteboard에 복사되는 메서드
    private func copyInviteCode() {
        useCase.getInviteCode()
            .subscribe(onNext: { [weak self] code in
                guard let self = self else { return }
                self.state.copyToClipboard.accept(code)
                self.state.showMessage.accept("초대 코드가 복사되었습니다")
            }, onError: { [weak self] error in
                let message: String

                if let repoError = error as? RepositoryError {
                    message = repoError.localizedDescription
                } else {
                    message = "오류가 발생했습니다."
                }

                self?.state.showMessage.accept(message)
            })
            .disposed(by: disposeBag)
    }

    // 화면에 접속했을 때 초대 코드를 보여주는 메서드
    private func showInviteCode() {
        useCase.getInviteCode()
            .subscribe(onNext: { [weak self] code in
                self?.state.inviteCode.accept(code)
            }, onError: { [weak self] error in
                let message: String

                if let repoError = error as? RepositoryError {
                    message = repoError.localizedDescription
                } else {
                    message = "초대 코드를 불러오지 못했습니다."
                }

                self?.state.showMessage.accept(message)
            })
            .disposed(by: disposeBag)
    }

}
