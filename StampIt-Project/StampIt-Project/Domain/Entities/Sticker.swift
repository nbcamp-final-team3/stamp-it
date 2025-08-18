//
//  Sticker.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/5/25.
//

import Foundation

struct Sticker: Hashable {
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
}

enum StickerType: String, Hashable {
    case stampGray
    case stampRed
    case stampBlue
    case stampYellow
    case stampPurple
}

// MARK: - Presentation Model 변환

extension Sticker {
    func toPresentation() -> StickerUI {
        return StickerUI(
            userID: self.userID,
            stickerID: self.stickerID,
            groupID: self.groupID,
            month: self.month,
            type: self.type,
            pinNumber: self.pinNumber,
            createdAt: self.createdAt,
            missionID: self.missionID,
            maxStickers: self.maxStickers,
            assignedBy: self.assignedBy,
            zigzagIndex: .zero,
            shouldBlur: false,
        )
    }
}
