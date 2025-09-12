//
//  StampFirestore.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore

struct StampFirestore: Codable {
    let stampId: String
    let userId: String
    let groupId: String
    let month: String               // "YYYY-MM"
    let type: String                // "일반", "특별", 현재 미사용
    let pinNumber: Int
    let createdAt: Timestamp
    let missionId: String
    let maxStamps: Int
    let assignedBy: String

    var documentID: String {
        return stampId
    }
}

// MARK: - Domain Model 변환
extension StampFirestore {
    func toDomainModel() -> Stamp {
        return Stamp(
            userID: self.userId,
            stampID: self.stampId,
            groupID: self.groupId,
            month: self.month,
            type: StampType(rawValue: self.type) ?? .stampRed,
            pinNumber: self.pinNumber,
            createdAt: self.createdAt.dateValue(),
            missionID: self.missionId,
            maxStamps: self.maxStamps,
            assignedBy: self.assignedBy
        )
        
    }
}
