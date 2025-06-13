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
import FirebaseFirestore

final class SendInviteViewModel: ViewModelProtocol {

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
    private let createInviteUseCase: CreateInviteUseCaseProtocol
    private var currentGroupId: String?

    // MARK: - Init
    init(createInviteUseCase: CreateInviteUseCaseProtocol = CreateInviteUseCase()) {
        let inviteCodeRelay = BehaviorRelay<String>(value: "복사 이미지를 클릭해주세요!")
        let showCopyMessageRelay = PublishRelay<String>()

        self.state = State(
            inviteCode: inviteCodeRelay,
            showCopyMessage: showCopyMessageRelay
        )
        self.createInviteUseCase = createInviteUseCase

        // Action 처리
        action
            .subscribe(onNext: { [weak self] action in
                switch action {
                case .copyButtonTapped:
                    guard let self = self,
                          let groupId = self.currentGroupId else { return }
                    
                    self.createInviteUseCase.createInvite(groupId: groupId)
                        .flatMap { [weak self] code in
                            self?.createInviteUseCase.copyInviteCode(code) ?? .empty()
                        }
                        .subscribe(onNext: { [weak self] message in
                            self?.state.showCopyMessage.accept(message)
                        }, onError: { [weak self] error in
                            self?.state.showCopyMessage.accept("초대 코드 생성 실패: \(error.localizedDescription)")
                        })
                        .disposed(by: self.disposeBag)
                }
            })
            .disposed(by: disposeBag)
            
        // 현재 유저의 그룹 ID 가져오기
        fetchCurrentUserGroup()
    }
    
    // MARK: - Methods
    private func fetchCurrentUserGroup() {
        let testGroupId = "testGroup003"
        
        self.currentGroupId = testGroupId
        
        // 초대 코드 표시 업데이트
        if let groupId = currentGroupId {
            state.inviteCode.accept(groupId)
        }
    }
}
