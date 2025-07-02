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
    let groupId: String
    let month: String
    let type: StickerType
    let pinNumber: Int
    let createdAt: Date
    let missionId: String
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
