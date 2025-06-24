//
//  UserQuery.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation

struct UserQuery {
    let userIds: [String]?
    let groupIds: [String]?
    let nicknameContains: String?
    let createdAfter: Date?
    let QueryOrder: QueryOrder?
    let limit: Int?
    
    // MARK: - 편의 생성자들
    static func byId(_ id: String) -> UserQuery {
        return UserQuery(userIds: [id], groupIds: nil, nicknameContains: nil, createdAfter: nil, QueryOrder: nil, limit: nil)
    }
    
    static func byGroup(_ groupId: String) -> UserQuery {
        return UserQuery(userIds: nil, groupIds: [groupId], nicknameContains: nil, createdAfter: nil, QueryOrder: nil, limit: nil)
    }
}
