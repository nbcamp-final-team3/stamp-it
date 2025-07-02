//
//  MembershipManagerProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

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
    func updateMemberProfileImage(groupId: String, userId: String, profileImage: String) -> Observable<Void>
    func deleteGroupMemberships(groupId: String) -> Observable<Void>
    func updateMemberNickname(groupId: String, userId: String, nickname: String) -> Observable<Void>
    
    // TODO: 그룹 변경 관련 (기존 switchUserGroup 분해) > 리팩토링 후 Repo로 이동시켜야함
    func switchUserGroup(
        userId: String,
        fromGroupId: String,
        toGroupId: String,
        userNickname: String,
        profileImage: String
    ) -> Observable<Void>
}
