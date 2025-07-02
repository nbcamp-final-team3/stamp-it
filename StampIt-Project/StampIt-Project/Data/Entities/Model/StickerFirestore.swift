//
//  StickerFirestore.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore

struct StickerFirestore: Codable {
    let stickerId: String
    let userId: String
    let groupId: String
    let month: String               // "YYYY-MM"
    let type: String                // "일반", "특별", 현재 미사용
    let pinNumber: Int
    let createdAt: Timestamp
    let missionId: String
    let maxStickers: Int
    let assignedBy: String

    var documentID: String {
        return stickerId
    }
}

// MARK: - Domain Model 변환
extension StickerFirestore {
    func toDomainModel() -> Sticker {
        return Sticker(
            userID: self.userId,
            stickerID: self.stickerId,
            groupId: self.groupId,
            month: self.month,
            type: StickerType(rawValue: self.type) ?? .stampRed,
            pinNumber: self.pinNumber,
            createdAt: self.createdAt.dateValue(),
            missionId: self.missionId,
            maxStickers: self.maxStickers,
            assignedBy: self.assignedBy
        )
        
    }
}
