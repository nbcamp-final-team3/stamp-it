//
//  SendInviteViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/7/25.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit


class SendInviteViewModel: ViewModelProtocol {

    // MARK: - Action&State
    enum Action {
        case copyButtonTapped
    }

    struct State {
        let inviteCode: BehaviorRelay<String>
        let showCopyMessage: PublishRelay<String>
    }

    // MARK: - Properties
    var disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state: State

    // MARK: - Init
    init() {
        let inviteCode = Self.generateInviteCode()
        let inviteCodeRelay = BehaviorRelay<String>(value: inviteCode)
        let showCopyMessageRelay = PublishRelay<String>()

        self.state = State(
            inviteCode: inviteCodeRelay,
            showCopyMessage: showCopyMessageRelay
        )

        // Action 처리
        action
            .subscribe(onNext: { action in
                switch action {
                case .copyButtonTapped:
                    UIPasteboard.general.string = inviteCode
                    showCopyMessageRelay.accept("초대 코드가 복사되었습니다")
                }
            }).disposed(by: disposeBag)
    }

    // MARK: - Helper 초대 코드 생성 함수
    private static func generateInviteCode(length: Int = 8) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }


}
