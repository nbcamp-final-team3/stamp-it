//
//  GroupProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

//protocol GroupManagerProtocol {
//    // 기본 CRUD
//    func fetchGroup(groupId: String) -> Observable<GroupFirestore>
//    func fetchGroupOnce(groupId: String) -> Observable<GroupFirestore>
//    func createGroup(_ group: GroupFirestore) -> Observable<Void>
//    func updateGroup(_ group: GroupFirestore) -> Observable<Void>
//    func deleteGroup(groupId: String) -> Observable<Void>
//    
//    // 편의 업데이트 메서드들
//    func updateGroupName(groupId: String, name: String, changedAt: Date) -> Observable<Void>
//    func updateGroupLeader(groupId: String, newLeaderId: String) -> Observable<Void>
//    func updateMemberCount(groupId: String, count: Int) -> Observable<Void>
//}

// MARK: - GroupManager Protocol (기존 FirestoreManager 메서드 통합)
protocol GroupManagerProtocol: FullCRUDRepository where Entity == GroupFirestore, ID == String, Query == GroupQuery {
    // 기본 CRUD
    func fetchGroup(groupId: String) -> Observable<GroupFirestore>
    func createGroup(_ group: GroupFirestore) -> Observable<Void>
    func updateGroup(_ group: GroupFirestore) -> Observable<Void>
    func deleteGroup(groupId: String) -> Observable<Void>
    
    // 편의 업데이트 메서드들 (기존 FirestoreManager 메서드)
    func updateGroupName(groupId: String, name: String, changedAt: Date) -> Observable<Void>
    func updateGroupLeader(groupId: String, newLeaderId: String) -> Observable<Void>
    
    // 초대 관련 메서드들 (기존 FirestoreManager 메서드)
    func fetchGroupInviteCode(groupId: String) -> Observable<String>
    func fetchGroupByInviteCode(inviteCode: String) -> Observable<GroupFirestore>
    
    // 초대 코드 관리 (기존 FirestoreManager 메서드)
    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore>
    func createInvite(_ invite: InviteFirestore) -> Observable<Void>
    func deleteInvite(inviteCode: String) -> Observable<Void>
    func deleteUserInvites(userId: String) -> Observable<Void>
    func deleteGroupInvites(groupId: String) -> Observable<Void>
    
    // 앱 미션 관련 (기존 FirestoreManager 메서드)
    func fetchAppMissions() -> Observable<[AppMissionFirestore]>
}
