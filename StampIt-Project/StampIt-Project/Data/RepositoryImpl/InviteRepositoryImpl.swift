//
//  InviteRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift

final class InviteRepositoryImpl: InviteRepository {
    private let groupManager: GroupManager
    private let membershipManager: MembershipManager
    private let userManager: UserManager
    
    init(
        groupManager: GroupManager,
        membershipManager: MembershipManager,
        userManager: UserManager
    ) {
        self.groupManager = groupManager
        self.membershipManager = membershipManager
        self.userManager = userManager
    }
    
    
    func fetchInvite(inviteCode: String) -> Observable<Invitation> {
        return groupManager.fetchInvite(inviteCode: inviteCode)
            .map { $0.toDomainModel() }
    }
    
    func addMember(groupId: String, member: Member) -> Observable<Void> {
        let membershipFirestore = member.toMembershipFirestoreModel(groupId: groupId)
        return membershipManager.addMember(groupId: groupId, member: membershipFirestore)
    }
    
    func createInvite(_ invite: Invitation) -> Observable<Void> {
        let firestoreInvite = invite.toFirestoreModel()
        return groupManager.createInvite(firestoreInvite)
    }
    
    func fetchGroup(groupId: String) -> Observable<Group> {
        return groupManager.fetchGroup(groupId: groupId)
            .map { $0.toDomainModel(members: []) }
    }
    
    func fetchUserOnce(userId: String) -> Observable<User> {
        return userManager.fetchUserOnce(userId: userId)
            .map { $0.toDomainModel() }
    }

    func fetchGroupByInviteCode(inviteCode: String) -> Observable<Group> {
        return groupManager.fetchGroupByInviteCode(inviteCode: inviteCode)
            .map { $0.toDomainModel(members: []) }
    }

    func fetchGroupMemberCount(groupId: String) -> Observable<Int> {
        return membershipManager.fetchGroupMemberCount(groupId: groupId)
    }

    func deleteGroup(groupId: String) -> Observable<Void> {
        return groupManager.deleteGroup(groupId: groupId)
    }

    func switchUserGroup(userId: String, fromGroupId: String, toGroupId: String, userNickname: String, profileImage: String) -> Observable<Void> {
        return membershipManager.switchUserGroup(
            userId: userId,
            fromGroupId: fromGroupId,
            toGroupId: toGroupId,
            userNickname: userNickname,
            profileImage: profileImage
        )
    }
}
