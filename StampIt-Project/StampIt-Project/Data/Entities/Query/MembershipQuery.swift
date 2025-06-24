//
//  MembershipQuery.swift
//  StampIt-Project
//
//  Created by iOS study on 6/24/25.
//

import Foundation

// MARK: - MembershipQuery 정의
struct MembershipQuery {
    let membershipIds: [String]?
    let groupIds: [String]?
    let userIds: [String]?
    let isLeaderOnly: Bool?
    let joinedAfter: Date?
    let orderBy: QueryOrder?
    let limit: Int?
    
    static func byGroup(_ groupId: String) -> MembershipQuery {
        return MembershipQuery(membershipIds: nil, groupIds: [groupId], userIds: nil, isLeaderOnly: nil, joinedAfter: nil, orderBy: nil, limit: nil)
    }
    
    static func byUser(_ userId: String) -> MembershipQuery {
        return MembershipQuery(membershipIds: nil, groupIds: nil, userIds: [userId], isLeaderOnly: nil, joinedAfter: nil, orderBy: nil, limit: nil)
    }
    
    static func leaders() -> MembershipQuery {
        return MembershipQuery(membershipIds: nil, groupIds: nil, userIds: nil, isLeaderOnly: true, joinedAfter: nil, orderBy: nil, limit: nil)
    }
}
