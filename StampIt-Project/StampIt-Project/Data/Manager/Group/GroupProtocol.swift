//
//  GroupProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

protocol GroupManagerProtocol {
    // 기본 CRUD
    func fetchGroup(groupId: String) -> Observable<GroupFirestore>
    func fetchGroupOnce(groupId: String) -> Observable<GroupFirestore>
    func createGroup(_ group: GroupFirestore) -> Observable<Void>
    func updateGroup(_ group: GroupFirestore) -> Observable<Void>
    func deleteGroup(groupId: String) -> Observable<Void>
    
    // 편의 업데이트 메서드들
    func updateGroupName(groupId: String, name: String, changedAt: Date) -> Observable<Void>
    func updateGroupLeader(groupId: String, newLeaderId: String) -> Observable<Void>
    func updateMemberCount(groupId: String, count: Int) -> Observable<Void>
    func updateInviteCode(groupId: String, newInviteCode: String) -> Observable<Void>
    
    // 초대 관련
    func fetchGroupByInviteCode(inviteCode: String) -> Observable<GroupFirestore>
    func fetchGroupInviteCode(groupId: String) -> Observable<String>
}
