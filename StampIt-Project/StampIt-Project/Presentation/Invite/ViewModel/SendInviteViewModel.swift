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
import FirebaseAuth

final class SendInviteViewModel: ViewModelProtocol {
    // MARK: - Action & State
    enum Action {
        case copyButtonTapped
    }

    struct State {
        let inviteCode = BehaviorRelay<String>(value: "")
        let showMessage = PublishRelay<String>()
    }

    // MARK: - Properties
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()
    private let firestoreManager = FirestoreManager()
    
    // MARK: - Init
    init() {
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
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.state.showMessage.accept("로그인이 필요합니다")
            return
        }
        
        firestoreManager.fetchUserOnce(userId: currentUserId)
            .subscribe(onNext: { [weak self] user in
                guard let self = self else { return }
                
                let groupId = user.groupId
                UIPasteboard.general.string = groupId
                self.state.showMessage.accept("초대 코드가 복사되었습니다")
                
            }, onError: { [weak self] error in
                self?.state.showMessage.accept("사용자 정보 조회 실패: \(error.localizedDescription)")
            })
            .disposed(by: self.disposeBag)
    }
}
