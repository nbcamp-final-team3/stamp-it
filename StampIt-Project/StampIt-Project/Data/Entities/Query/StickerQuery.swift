//
//  StickerQuery.swift
//  StampIt-Project
//
//  Created by iOS study on 6/24/25.
//

import Foundation

// MARK: - StickerQuery 정의
struct StickerQuery {
    let stickerIds: [String]?
    let userIds: [String]?
    let groupIds: [String]?
    let months: [String]?
    let pinNumbers: [Int]?
    let types: [String]?
    let createdAfter: Date?
    let orderBy: QueryOrder?
    let limit: Int?
    
    static func byUser(_ userId: String) -> StickerQuery {
        return StickerQuery(stickerIds: nil, userIds: [userId], groupIds: nil, months: nil, pinNumbers: nil, types: nil, createdAfter: nil, orderBy: nil, limit: nil)
    }
    
    static func byUserAndMonth(_ userId: String, month: String) -> StickerQuery {
        return StickerQuery(stickerIds: nil, userIds: [userId], groupIds: nil, months: [month], pinNumbers: nil, types: nil, createdAfter: nil, orderBy: nil, limit: nil)
    }
    
    static func byUserAndPin(_ userId: String, pinNumber: Int) -> StickerQuery {
        return StickerQuery(stickerIds: nil, userIds: [userId], groupIds: nil, months: nil, pinNumbers: [pinNumber], types: nil, createdAfter: nil, orderBy: nil, limit: nil)
    }
    
    static func byGroup(_ groupId: String) -> StickerQuery {
        return StickerQuery(stickerIds: nil, userIds: nil, groupIds: [groupId], months: nil, pinNumbers: nil, types: nil, createdAfter: nil, orderBy: nil, limit: nil)
    }
    
    static func byGroupAndMonth(_ groupId: String, month: String) -> StickerQuery {
        return StickerQuery(stickerIds: nil, userIds: nil, groupIds: [groupId], months: [month], pinNumbers: nil, types: nil, createdAfter: nil, orderBy: nil, limit: nil)
    }
}
