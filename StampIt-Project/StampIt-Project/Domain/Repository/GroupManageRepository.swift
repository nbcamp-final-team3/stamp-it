//
//  GroupManageRepository.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/26/25.
//

import Foundation
import RxSwift

protocol GroupManageRepository {
    /// 리더 위임
    func delegateLeader(to memberId: String, groupId: String) -> Observable<Void>
    
    /// 그룹 멤버 목록 가져오기
    func fetchGroupMembers(groupId: String) -> Observable<[Member]>
    
    /// 특정 그룹의 리더 조회
    func fetchGroupLeader(groupId: String) -> Observable<Member?>
    
    /// 특정 그룹의 특정 멤버 조회
    func fetchMember(groupId: String, userId: String) -> Observable<Member?>
    
    /// 그룹의 모든 멤버 조회 (쿼리 기반)
    func fetchMembersByGroup(groupId: String) -> Observable<[Member]>
    
    /// 멤버 정보 업데이트
    func updateMemberRole(groupId: String, userId: String, isLeader: Bool) -> Observable<Void>

    /// 멤버 내보내기
    func exportMember(member: User) -> Observable<User>
}
