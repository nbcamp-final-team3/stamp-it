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
    private let firestoreManager = FirestoreManager.shared
    private var currentGroupId: String?

    // MARK: - Init
    init() {
        let inviteCodeRelay = BehaviorRelay<String>(value: "복사 이미지를 클릭해주세요!")
        let showCopyMessageRelay = PublishRelay<String>()

        self.state = State(
            inviteCode: inviteCodeRelay,
            showCopyMessage: showCopyMessageRelay
        )

        // Action 처리
        action
            .subscribe(onNext: { [weak self] action in
                switch action {
                case .copyButtonTapped:
                    guard let self = self,
                          let groupId = self.currentGroupId else { return }
                    
                    // 초대장 생성
                    let invite = InviteFirestore(
                        inviteCode: groupId,
                        groupId: groupId,
                        createdBy: "currentUserId003", // TODO: 실제 현재 유저 ID로 교체
                        createdAt: Timestamp(date: Date()),
                        expiredAt: nil
                    )
                    
                    // Firestore에 초대장 저장
                    self.firestoreManager.createInvite(invite)
                        .subscribe(onNext: { [weak self] _ in
                            // 초대 코드 복사
                            UIPasteboard.general.string = groupId
                            self?.state.showCopyMessage.accept("초대 코드가 복사되었습니다")
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
