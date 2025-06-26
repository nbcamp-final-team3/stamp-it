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
        // 1. 그룹의 리더 정보 업데이트
        return groupManager.updateGroupLeader(groupId: groupId, newLeaderId: memberId)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 2. 현재 리더를 일반 멤버로 변경 (membership에서 리더 찾기)
                return self.membershipManager.fetchList(query: .leaders())
                    .flatMap { memberships -> Observable<Void> in
                        let currentLeaderMembership = memberships.first { $0.groupId == groupId }
                        guard let leaderMembership = currentLeaderMembership else {
                            return Observable.error(RepositoryError.userNotFound)
                        }
                        
                        // 현재 리더를 일반 멤버로 변경
                        return self.membershipManager.updateFields(id: leaderMembership.documentID, fields: ["isLeader": false])
                    }
            }
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 3. 새로운 리더로 지정
                return self.membershipManager.fetchList(query: .byGroupIdAndUserId(groupId: groupId, userId: memberId))
                    .flatMap { memberships -> Observable<Void> in
                        guard let membership = memberships.first else {
                            return Observable.error(RepositoryError.userNotFound)
                        }
                        
                        return self.membershipManager.updateFields(id: membership.documentID, fields: ["isLeader": true])
                    }
            }
    }
    
    func fetchGroupMembers(groupId: String) -> Observable<[Member]> {
        return membershipManager.fetchList(query: .byGroup(groupId))
            .map { memberships in
                return memberships.map { membership in
                    membership.toDomainModel()
                }
            }
    }
} 
