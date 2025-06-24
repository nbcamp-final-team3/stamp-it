//
//  MembershipManagerProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

//protocol MembershipManagerProtocol {
//    // 기본 CRUD
//    func fetchMemberships(groupId: String) -> Observable<[GroupMembershipFirestore]>
//    func fetchMembership(membershipId: String) -> Observable<GroupMembershipFirestore?>
//    func fetchUserMemberships(userId: String) -> Observable<[GroupMembershipFirestore]>
//    func createMembership(_ membership: GroupMembershipFirestore) -> Observable<Void>
//    func updateMembership(_ membership: GroupMembershipFirestore) -> Observable<Void>
//    func deleteMembership(membershipId: String) -> Observable<Void>
//    
//    // 편의 메서드들
//    func addUserToGroup(userId: String, groupId: String, nickname: String, profileImage: String?) -> Observable<Void>
//    func removeUserFromGroup(userId: String, groupId: String) -> Observable<Void>
//    func updateMembershipNickname(membershipId: String, nickname: String) -> Observable<Void>
//    func updateMembershipProfileImage(membershipId: String, profileImage: String) -> Observable<Void>
//    func updateLeaderStatus(membershipId: String, isLeader: Bool) -> Observable<Void>
//    
//    // 조회 관련
//    func fetchGroupMemberCount(groupId: String) -> Observable<Int>
//    func fetchGroupLeader(groupId: String) -> Observable<GroupMembershipFirestore?>
//    func fetchOldestMember(groupId: String, excludeUserId: String) -> Observable<GroupMembershipFirestore?>
//    
//    // 삭제 관련
//    func deleteUserMemberships(userId: String) -> Observable<Void>
//    func deleteGroupMemberships(groupId: String) -> Observable<Void>
//}

// MARK: - MembershipManager Protocol (기존 Member 메서드 통합)
protocol MembershipManagerProtocol: FullCRUDRepository where Entity == GroupMembershipFirestore, ID == String, Query == MembershipQuery {
    // 기본 CRUD
    func fetchMembers(groupId: String) -> Observable<[GroupMembershipFirestore]>
    func addMember(groupId: String, member: GroupMembershipFirestore) -> Observable<Void>
    func removeMember(groupId: String, userId: String) -> Observable<Void>
    
    // 편의 업데이트 메서드들 (기존 FirestoreManager 메서드)
    func updateMember(groupId: String, userId: String, query: [String: String]) -> Observable<Void>
    func updateMemberLeaderStatus(groupId: String, userId: String, isLeader: Bool) -> Observable<Void>
    func fetchOldestMember(groupId: String, excludeUserId: String) -> Observable<GroupMembershipFirestore>
    func fetchGroupMemberCount(groupId: String) -> Observable<Int>
    
    // TODO: 그룹 변경 관련 (기존 switchUserGroup 분해) > 리팩토링 후 Repo로 이동시킬 예정
    func switchUserGroup(
        userId: String,
        fromGroupId: String,
        toGroupId: String,
        userNickname: String,
        profileImage: String
    ) -> Observable<Void>
}
