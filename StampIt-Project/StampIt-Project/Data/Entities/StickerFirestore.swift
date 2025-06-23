//
//  StickerFirestore.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

// 1. missionTitle → missionId 변경으로 정규화
// 2. 미션 정보 변경 시 스티커 데이터 동기화 불필요
// 3. 미션과 스티커 간 명확한 참조 관계 설정

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
            title: self.missionId,
            description: self.missionId,
            imageURL: "",
            type: StickerType(rawValue: self.type) ?? .stampRed,
            createdAt: self.createdAt.dateValue(),
            maxStickers: self.maxStickers,
            pinNumber: self.pinNumber,
            assignedBy: self.assignedBy
        )
        
    }
}
