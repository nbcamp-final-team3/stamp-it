//
//  InviteRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift

final class InviteRepositoryImpl: InviteRepository {

    private let firestoreManager: FirestoreManagerProtocol

    init(firestoreManager: FirestoreManagerProtocol) {
        self.firestoreManager = firestoreManager
    }

    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore> {
        firestoreManager.fetchInvite(inviteCode: inviteCode)
    }

    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void> {
        firestoreManager.addMember(groupId: groupId, member: member)
    }

    func createInvite(_ invite: InviteFirestore) -> Observable<Void> {
        firestoreManager.createInvite(invite)
    }

    func updateUser(_ user: UserFirestore) -> Observable<Void> {
        firestoreManager.updateUser(user)
    }

    func fetchGroup(groupId: String) -> Observable<GroupFirestore> {
        firestoreManager.fetchGroup(groupId: groupId)
    }

    func fetchUserOnce(userId: String) -> Observable<UserFirestore> {
        firestoreManager.fetchUser(userId: userId)
    }

    func fetchGroupByInviteCode(inviteCode: String) -> Observable<GroupFirestore> {
        firestoreManager.fetchGroupByInviteCode(inviteCode: inviteCode)
    }

    func fetchGroupMemberCount(groupId: String) -> Observable<Int> {
        firestoreManager.fetchGroupMemberCount(groupId: groupId)
    }

    func deleteGroup(groupId: String) -> Observable<Void> {
        firestoreManager.deleteGroup(groupId: groupId)
    }

    func switchUserGroup(userId: String, fromGroupId: String, toGroupId: String, userNickname: String) -> Observable<Void> {
        firestoreManager.switchUserGroup(
            userId: userId,
            fromGroupId: fromGroupId,
            toGroupId: toGroupId,
            userNickname: userNickname
        )
    }
}
