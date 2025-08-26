//
//  StickerUI.swift
//  StampIt-Project
//
//  Created by kingj on 6/30/25.
//

import Foundation

struct StampBoardStamp: Hashable {
    let userID: String
    let stickerID: String
    let groupID: String
    let month: String
    let type: StickerType
    let pinNumber: Int
    let createdAt: Date
    let missionID: String
    let maxStickers: Int
    let assignedBy: String
    var zigzagIndex: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(stickerID)
        hasher.combine(type)
        hasher.combine(zigzagIndex)
    }
    
    static func == (lhs: StampBoardStamp, rhs: StampBoardStamp) -> Bool {
        lhs.stickerID == rhs.stickerID &&
        lhs.type == rhs.type &&
        lhs.zigzagIndex == rhs.zigzagIndex
    }
}

// MARK: - Mapper

extension StampBoardStamp {
    static func map(_ sticker: Sticker) -> StampBoardStamp {
        StampBoardStamp(
            userID: sticker.userID,
            stickerID: sticker.stickerID,
            groupID: sticker.groupID,
            month: sticker.month,
            type: sticker.type,
            pinNumber: sticker.pinNumber,
            createdAt: sticker.createdAt,
            missionID: sticker.missionID,
            maxStickers: sticker.maxStickers,
            assignedBy: sticker.assignedBy,
            zigzagIndex: .zero,
        )
    }
    
    static func map(
        _ sticker: StampBoardStamp,
        type: StickerType = .gray
    ) -> StampBoardStamp {
        StampBoardStamp(
            userID: sticker.userID,
            stickerID: sticker.stickerID,
            groupID: sticker.groupID,
            month: sticker.month,
            type: type,
            pinNumber: sticker.pinNumber,
            createdAt: sticker.createdAt,
            missionID: sticker.missionID,
            maxStickers: sticker.maxStickers,
            assignedBy: sticker.assignedBy,
            zigzagIndex: .zero,
        )
    }
}
