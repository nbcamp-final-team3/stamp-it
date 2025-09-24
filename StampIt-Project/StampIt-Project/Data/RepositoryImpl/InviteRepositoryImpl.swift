//
//  InviteRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift
import FirebaseFirestore

final class InviteRepositoryImpl: InviteRepositoryProtocol {
    private let groupManager: any GroupManagerProtocol
    private let membershipManager: any MembershipManagerProtocol
    private let userManager: any UserManagerProtocol
    // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
    private let missionManager: any MissionManagerProtocol
    private let stampManager: any StampManagerProtocol
    private let noticeManager: any NoticeManagerProtocol

    init(
        groupManager: any GroupManagerProtocol,
        membershipManager: any MembershipManagerProtocol,
        userManager: any UserManagerProtocol,
         missionManager: any MissionManagerProtocol,
         stampManager: any StampManagerProtocol,
         noticeManager: any NoticeManagerProtocol
        // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
    ) {
        self.groupManager = groupManager
        self.membershipManager = membershipManager
        self.userManager = userManager
        // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
         self.missionManager = missionManager
         self.stampManager = stampManager
         self.noticeManager = noticeManager
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
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 1. 기존 멤버들 조회 (새 멤버 제외)
                return self.membershipManager.fetchList(query: .byGroup(groupId))
                    .flatMap { memberships -> Observable<Void> in
                        // 새 멤버 제외하고 기존 멤버들에게만 알림
                        let existingMembers = memberships.filter { $0.userId != member.userID }
                        
                        // 2. 각 기존 멤버에게 알림 생성
                        let noticeObservables = existingMembers.map { existingMember in
                            let notice = NoticeFirestore(
                                noticeId: UUID().uuidString,
                                title: "새로운 멤버가 들어왔어요!",
                                description: "\(member.nickname)님이 그룹에 합류했습니다.",
                                category: NoticeCategory.member.rawValue,
                                createdAt: Timestamp(date: Date()),
                                url: "stamp-it://member",
                                isRead: false,
                                userId: existingMember.userId  // 기존 멤버에게 전송
                            )
                            // 서버 트리거 함수 호출
                            return self.noticeManager.create(notice: notice)
                        }
                        
                        // 3. 모든 알림을 병렬로 전송
                        return Observable.zip(noticeObservables).map { _ in () }
                    }
            }
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

    // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
    func cleanupUserDataWithRetry(userId: String, currentGroupId: String, maxRetries: Int) -> Observable<Void> {
        return stampManager.deleteUserStamps(userId: userId, groupId: currentGroupId)
                    .retry(maxRetries)
                    .flatMap { _ in
                        return self.missionManager.deleteReceivedMissions(userId: userId, groupId: currentGroupId)
                            .retry(maxRetries)
                    }
                    .timeout(.seconds(5), scheduler: MainScheduler.instance)
                    .catch { error in
                        return Observable.error(GroupExitError.dataCleanupFailed(error.localizedDescription))
                    }
    }
}
