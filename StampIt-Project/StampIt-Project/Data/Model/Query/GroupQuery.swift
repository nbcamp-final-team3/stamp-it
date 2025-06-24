//
//  GroupQuery.swift
//  StampIt-Project
//
//  Created by iOS study on 6/24/25.
//

import Foundation

// MARK: - GroupQuery 정의
struct GroupQuery {
    let groupIds: [String]?
    let leaderIds: [String]?
    let inviteCodes: [String]?
    let nameContains: String?
    let createdAfter: Date?
    let orderBy: QueryOrder?
    let limit: Int?
    
    static func byId(_ id: String) -> GroupQuery {
        return GroupQuery(groupIds: [id], leaderIds: nil, inviteCodes: nil, nameContains: nil, createdAfter: nil, orderBy: nil, limit: nil)
    }
    
    static func byInviteCode(_ inviteCode: String) -> GroupQuery {
        return GroupQuery(groupIds: nil, leaderIds: nil, inviteCodes: [inviteCode], nameContains: nil, createdAfter: nil, orderBy: nil, limit: nil)
    }
    
    static func byLeader(_ leaderId: String) -> GroupQuery {
        return GroupQuery(groupIds: nil, leaderIds: [leaderId], inviteCodes: nil, nameContains: nil, createdAfter: nil, orderBy: nil, limit: nil)
    }
}
