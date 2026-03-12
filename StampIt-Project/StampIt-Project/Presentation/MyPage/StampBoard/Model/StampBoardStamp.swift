//
//  StampBoardStamp.swift
//  StampIt-Project
//
//  Created by kingj on 6/30/25.
//

import Foundation

// MARK: - Stamp 상태

struct StampBoardStamp: Hashable {
    let userID: String
    let stampID: String
    let groupID: String
    let month: String
    let createdAt: Date
    let missionID: String
    let maxStamps: Int
    let assignedBy: String
}

// MARK: - Stamp 표현

struct StampCellAppearance: Hashable {
    var color: StampType
    var isHighlighted: Bool
}

struct StampBoardViewState: Hashable {
    let collectdStamp: Int
    let completedBoard: Int
    let stampContent: [StampCellIdentity: StampCellContent]
    let stampAppearance: [StampCellIdentity: StampCellAppearance]
    let stampIdentityByPage: [[StampCellIdentity]]
}

// MARK: - Mapper

extension StampBoardStamp {
    static func map(_ stamp: Stamp) -> StampBoardStamp {
        StampBoardStamp(
            userID: stamp.userID,
            stampID: stamp.stampID,
            groupID: stamp.groupID,
            month: stamp.month,
            createdAt: stamp.createdAt,
            missionID: stamp.missionID,
            maxStamps: stamp.maxStamps,
            assignedBy: stamp.assignedBy,
        )
    }
    
    static func map(
        _ stamp: StampBoardStamp,
    ) -> StampBoardStamp {
        StampBoardStamp(
            userID: stamp.userID,
            stampID: stamp.stampID,
            groupID: stamp.groupID,
            month: stamp.month,
            createdAt: stamp.createdAt,
            missionID: stamp.missionID,
            maxStamps: stamp.maxStamps,
            assignedBy: stamp.assignedBy,
        )
    }
}
