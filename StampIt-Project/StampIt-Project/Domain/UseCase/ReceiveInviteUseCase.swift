//
//  ReceiveInviteUseCase.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/13/25.
//

import Foundation
import RxSwift
import FirebaseFirestore
import FirebaseAuth

protocol ReceiveInviteUseCaseProtocol {
    func receiveInvite(withCode code: String) -> Observable<Void>
}

final class ReceiveInviteUseCase: ReceiveInviteUseCaseProtocol {
    private let firestoreManager: FirestoreManager
    
    init(firestoreManager: FirestoreManager = .shared) {
        self.firestoreManager = firestoreManager
    }
    
    func receiveInvite(withCode code: String) -> Observable<Void> {
        return firestoreManager.fetchInvite(inviteCode: code)
            .flatMap { [weak self] invite -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 새 멤버 생성 (Mock 데이터 사용)
                let newMember = MemberFirestore(
                    userId: "testUser004",
                    nickname: "테스트유저004",
                    joinedAt: Timestamp(),
                    isLeader: false
                )
                
                // 초대장의 그룹 ID로 멤버 추가
                return self.firestoreManager.addMember(groupId: invite.groupId, member: newMember)
            }
    }
}
