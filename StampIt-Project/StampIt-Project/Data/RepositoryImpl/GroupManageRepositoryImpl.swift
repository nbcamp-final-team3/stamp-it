//
//  GroupManageRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/26/25.
//

import Foundation
import RxSwift
import FirebaseFirestore

final class GroupManageRepositoryImpl: GroupManageRepository {
    
    private let groupManager: GroupManager
    private let userManager: UserManager
    private let membershipManager: MembershipManager
    
    init(groupManager: GroupManager, userManager: UserManager, membershipManager: MembershipManager) {
        self.groupManager = groupManager
        self.userManager = userManager
        self.membershipManager = membershipManager
    }
    
    // MARK: - GroupManageRepository
    
    func delegateLeader(to memberId: String, groupId: String) -> Observable<Void> {
        // 1. 현재 리더를 일반 멤버로 변경
        return fetchGroupLeader(groupId: groupId)
            .flatMap { [weak self] currentLeader -> Observable<Void> in
                guard let self = self, let leader = currentLeader else {
                    return Observable.error(RepositoryError.userNotFound)
                }
                
                return self.updateMemberRole(groupId: groupId, userId: leader.userID, isLeader: false)
            }
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 2. 새로운 리더로 지정
                return self.updateMemberRole(groupId: groupId, userId: memberId, isLeader: true)
            }
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 3. 그룹의 리더 정보 업데이트
                return self.groupManager.updateGroupLeader(groupId: groupId, newLeaderId: memberId)
            }
    }

    /// 특정 그룹의 리더 조회
    func fetchGroupLeader(groupId: String) -> Observable<Member?> {
        return membershipManager.fetchList(query: .leaders())
            .map { memberships in
                let groupLeader = memberships.first { $0.groupId == groupId }
                return groupLeader?.toDomainModel()  // GroupMembershipFirestore → Member 변환
            }
    }
    
    /// 특정 그룹의 특정 멤버 조회
    func fetchMember(groupId: String, userId: String) -> Observable<Member?> {
        // 주형: 그룹 매니저 체크 - GroupMembershipFirestore 활용
        return membershipManager.fetchList(query: .byGroupIdAndUserId(groupId: groupId, userId: userId))
            .map { memberships in
                return memberships.first?.toDomainModel()  // GroupMembershipFirestore → Member 변환
            }
    }
    
    /// 그룹의 모든 멤버 조회 (쿼리 기반)
    func fetchMembersByGroup(groupId: String) -> Observable<[Member]> {
        return membershipManager.fetchList(query: .byGroup(groupId))
            .map { memberships in
                return memberships.map { membership in
                    membership.toDomainModel()  // GroupMembershipFirestore → Member 변환
                }
            }
    }
    
    /// 멤버 정보 업데이트
    func updateMemberRole(groupId: String, userId: String, isLeader: Bool) -> Observable<Void> {
        return membershipManager.fetchList(query: .byGroupIdAndUserId(groupId: groupId, userId: userId))
            .flatMap { [weak self] memberships -> Observable<Void> in
                guard let self = self, let membership = memberships.first else {
                    return Observable.error(RepositoryError.userNotFound)
                }
                
                return self.membershipManager.updateFields(id: membership.documentID, fields: ["isLeader": isLeader])
            }
    }
    
    /// 그룹 멤버 목록 가져오기
    func fetchGroupMembers(groupId: String) -> Observable<[Member]> {
        return membershipManager.fetchList(query: .byGroup(groupId))
            .map { memberships in
                return memberships.map { membership in
                    membership.toDomainModel()  // GroupMembershipFirestore → Member 변환
                }
            }
    }
} 
