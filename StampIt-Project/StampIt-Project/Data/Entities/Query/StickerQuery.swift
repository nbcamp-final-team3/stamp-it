//
//  StickerQuery.swift
//  StampIt-Project
//
//  Created by iOS study on 6/24/25.
//

import Foundation

// MARK: - StickerQuery 정의
struct StickerQuery {
    let stickerId: [String]?
    let userId: [String]?
    let groupId: [String]?
    let missionId: [String]?
    let month: [String]?
    let pinNumber: [Int]?
    let type: [String]?
    let createdAt: Date?
    let orderBy: QueryOrder?
    let limit: Int?
    
    static func byUser(_ userId: String) -> StickerQuery {
        return StickerQuery(stickerId: nil, userId: [userId], groupId: nil, missionId: nil, month: nil, pinNumber: nil, type: nil, createdAt: nil, orderBy: nil, limit: nil)
    }
    
    static func byUserAndMonth(_ userId: String, month: String) -> StickerQuery {
        return StickerQuery(stickerId: nil, userId: [userId], groupId: nil, missionId: nil, month: [month], pinNumber: nil, type: nil, createdAt: nil, orderBy: nil, limit: nil)
    }
    
    static func byUserAndPin(_ userId: String, pinNumber: Int) -> StickerQuery {
        return StickerQuery(stickerId: nil, userId: [userId], groupId: nil, missionId: nil, month: nil, pinNumber: [pinNumber], type: nil, createdAt: nil, orderBy: nil, limit: nil)
    }
    
    static func byUserAndDescCreatedAfter(_ userId: String) -> StickerQuery {
        return StickerQuery(stickerId: nil, userId: [userId], groupId: nil, missionId: nil, month: nil, pinNumber: nil, type: nil, createdAt: nil, orderBy: QueryOrder(field: "createdAt", descending: false), limit: nil)
    }
    
    static func byGroup(_ groupId: String) -> StickerQuery {
        return StickerQuery(stickerId: nil, userId: nil, groupId: [groupId], missionId: nil, month: nil, pinNumber: nil, type: nil, createdAt: nil, orderBy: nil, limit: nil)
    }
    
    static func byGroupAndMonth(_ groupId: String, month: String) -> StickerQuery {
        return StickerQuery(stickerId: nil, userId: nil, groupId: [groupId], missionId: nil, month: [month], pinNumber: nil, type: nil, createdAt: nil, orderBy: nil, limit: nil)
    }

    static func byMission(_ missionId: String) -> StickerQuery {
        return StickerQuery(stickerId: nil, userId: nil, groupId: nil, missionId: [missionId], month: nil, pinNumber: nil, type: nil, createdAt: nil, orderBy: nil, limit: nil)
    }
}
