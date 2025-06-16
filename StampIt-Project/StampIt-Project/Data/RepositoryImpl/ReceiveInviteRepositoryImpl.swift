//
//  ReceiveInviteRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/16/25.
//

import Foundation
import RxSwift

final class ReceiveInviteRepositoryImpl: ReceiveInviteRepository {

    private let firestoreManager: FirestoreManagerProtocol

    init(firestoreManager: FirestoreManagerProtocol) {
        self.firestoreManager = firestoreManager
    }

    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore> {
        return firestoreManager.fetchInvite(inviteCode: inviteCode)
    }

    func fetchUserOnce(userId: String) -> Observable<UserFirestore> {
        return firestoreManager.fetchUserOnce(userId: userId)
    }

    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void> {
        return firestoreManager.addMember(groupId: groupId, member: member)
    }

    // 새 초대 코드 생성
    // 초대코드로 그룹 정보 조회
    // 초대코드 만료일
    // 그룹 기반으로 초대 코드 중복 되지 않게
}
