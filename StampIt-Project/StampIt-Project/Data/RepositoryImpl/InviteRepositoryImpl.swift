//
//  InviteRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift

final class InviteRepositoryImpl: InviteRepository {
    private let groupManager: any GroupManagerProtocol
    private let membershipManager: any MembershipManagerProtocol
    private let userManager: any UserManagerProtocol
    
    init(
        groupManager: any GroupManagerProtocol,
        membershipManager: any MembershipManagerProtocol,
        userManager: any UserManagerProtocol
    ) {
        self.groupManager = groupManager
        self.membershipManager = membershipManager
        self.userManager = userManager
    }
    
    
    func fetchInvite(inviteCode: String) -> Observable<Invite> {
        // 그룹에서 초대 코드로 조회 후 Invite 도메인 모델로 변환
        return groupManager.fetchGroupByInviteCode(inviteCode: inviteCode)
            .map { groupFirestore in
                return Invite(
                    inviteCode: groupFirestore.inviteCode,
                    groupId: groupFirestore.groupId,
                    groupName: groupFirestore.name,
                    invitedBy: groupFirestore.leaderId, // 리더가 초대한 것으로 간주
                    createdAt: groupFirestore.inviteCodeCreateAt?.dateValue() ?? Date()
                )
            }
    }
    
    func addMember(groupId: String, member: Member) -> Observable<Void> {
        let membershipFirestore = member.toMembershipFirestoreModel(groupId: groupId)
        return membershipManager.addMember(groupId: groupId, member: membershipFirestore)
    }
    
    func createInvite(_ invite: Invite) -> Observable<Void> {
            return groupManager.updateGroupInviteCode(
                groupId: invite.groupId,
                newInviteCode: invite.inviteCode
            )
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
