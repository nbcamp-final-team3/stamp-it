//
//  Stamp.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/5/25.
//

import Foundation

struct Stamp: Hashable {
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
}

enum StampType: String, Hashable {
    case gray
    case red
    case blue
    case yellow
    case purple

    static func from(raw: String) -> StampType {
        switch raw {
        case "stampRed", "red":
            return .red
        default:
            return .red
        }
    }
}

extension Stamp {
    func toPresentation() -> StampBoardStamp {
        StampBoardStamp(
            userID: self.userID,
            stampID: self.stampID,
            groupID: self.groupID,
            month: self.month,
            type: self.type,
            page: self.pinNumber,
            createdAt: self.createdAt,
            missionID: self.missionID,
            maxStamps: self.maxStamps,
            assignedBy: self.assignedBy,
        )
    }

    static var totalStamp: Int { 30 }
}
