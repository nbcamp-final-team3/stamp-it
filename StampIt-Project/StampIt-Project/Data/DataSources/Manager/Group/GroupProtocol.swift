//
//  GroupProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

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
    
    // 초대 관련 메서드들 (Group 내 inviteCode 필드 사용)
    func fetchGroupInviteCode(groupId: String) -> Observable<String>
    func fetchGroupByInviteCode(inviteCode: String) -> Observable<GroupFirestore>
    func updateGroupInviteCode(groupId: String, newInviteCode: String) -> Observable<Void>
    
    // 앱 미션 관련 (기존 FirestoreManager 메서드)
    func fetchAppMissions() -> Observable<[AppMissionFirestore]>
}
