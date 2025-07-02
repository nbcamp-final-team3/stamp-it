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
    // TODO: 사용자 데이터 정리
    // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
    // 🔧 필요시 주석 해제하여 활성화
    private let missionManager: MissionManager
    private let stickerManager: StickerManager
    
    init(
        groupManager: GroupManager,
        membershipManager: MembershipManager,
        userManager: UserManager,
        // TODO: 사용자 데이터 정리
        // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
        // 🔧 필요시 주석 해제하여 활성화
         missionManager: MissionManager,
         stickerManager: StickerManager
    ) {
        self.groupManager = groupManager
        self.membershipManager = membershipManager
        self.userManager = userManager
        // TODO: 사용자 데이터 정리
        // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
        // 🔧 필요시 주석 해제하여 활성화
         self.missionManager = missionManager
         self.stickerManager = stickerManager
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
    
    // TODO: 사용자 데이터 정리 (재시도 로직 포함)
    // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
    // 🔧 필요시 주석 해제하여 활성화
    // ⚡ 업데이트: Observable.zip을 사용하여 미션과 스티커를 동시에 삭제
    func cleanupUserDataWithRetry(userId: String, currentGroupId: String, maxRetries: Int) -> Observable<Void> {
        return Observable.zip(
            missionManager.deleteReceivedMissions(userId: userId, groupId: currentGroupId),
            stickerManager.deleteUserStickers(userId: userId, groupId: currentGroupId)
        )
        .map { _ in () }
        .retry(maxRetries)
        .timeout(.seconds(5), scheduler: MainScheduler.instance)
        .catch { error in
            return Observable.error(RepositoryError.dataError("사용자 데이터 정리 실패: \(error.localizedDescription)"))
        }
    }
}
