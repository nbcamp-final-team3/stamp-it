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

    func fetchInvite(inviteCode: String) -> Observable<Invitation> {
        firestoreManager.fetchInvite(inviteCode: inviteCode)
            .map { $0.toDomainModel() }
    }

    func addMember(groupId: String, member: Member) -> Observable<Void> {
        let firestoreMember = member.toFirestoreModel()
        return firestoreManager.addMember(groupId: groupId, member: firestoreMember)
    }

    func createInvite(_ invite: Invitation) -> Observable<Void> {
            let firestoreInvite = invite.toFirestoreModel()
            return firestoreManager.createInvite(firestoreInvite)
        }

    func fetchGroup(groupId: String) -> Observable<Group> {
        firestoreManager.fetchGroup(groupId: groupId)
            .map { $0.toDomainModel(members: []) }
    }

    func fetchUserOnce(userId: String) -> Observable<User> {
        firestoreManager.fetchUser(userId: userId)
            .map { $0.toDomainModel() }
    }

    func fetchGroupByInviteCode(inviteCode: String) -> Observable<Group> {
        firestoreManager.fetchGroupByInviteCode(inviteCode: inviteCode)
            .map { $0.toDomainModel(members: []) }
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
