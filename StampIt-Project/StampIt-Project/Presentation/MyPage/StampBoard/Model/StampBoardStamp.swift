//
//  StampUI.swift
//  StampIt-Project
//
//  Created by kingj on 6/30/25.
//

import Foundation

struct StampBoardStamp: Hashable {
    let userID: String
    let stampID: String
    let groupID: String
    let month: String
    let type: StampType
    let pinNumber: Int
    let createdAt: Date
    let missionID: String
    let maxStamps: Int
    let assignedBy: String
    var zigzagIndex: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(stampID)
        hasher.combine(type)
        hasher.combine(zigzagIndex)
    }
    
    static func == (lhs: StampBoardStamp, rhs: StampBoardStamp) -> Bool {
        lhs.stampID == rhs.stampID &&
        lhs.type == rhs.type &&
        lhs.zigzagIndex == rhs.zigzagIndex
    }
}

// MARK: - Mapper

extension StampBoardStamp {
    static func map(_ stamp: Stamp) -> StampBoardStamp {
        StampBoardStamp(
            userID: stamp.userID,
            stampID: stamp.stampID,
            groupID: stamp.groupID,
            month: stamp.month,
            type: stamp.type,
            pinNumber: stamp.pinNumber,
            createdAt: stamp.createdAt,
            missionID: stamp.missionID,
            maxStamps: stamp.maxStamps,
            assignedBy: stamp.assignedBy,
            zigzagIndex: .zero,
        )
    }
    
    static func map(
        _ stamp: StampBoardStamp,
        type: StampType = .gray
    ) -> StampBoardStamp {
        StampBoardStamp(
            userID: stamp.userID,
            stampID: stamp.stampID,
            groupID: stamp.groupID,
            month: stamp.month,
            type: type,
            pinNumber: stamp.pinNumber,
            createdAt: stamp.createdAt,
            missionID: stamp.missionID,
            maxStamps: stamp.maxStamps,
            assignedBy: stamp.assignedBy,
            zigzagIndex: .zero,
        )
    }
}
