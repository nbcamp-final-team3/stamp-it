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
    let title: String
    let description: String
    let imageURL: String
    let type: StickerType
    let createdAt: Date
    let maxStickers: Int
    let pinNumber: Int
    let assignedBy: String
}

enum StickerType: String, Hashable {
    case stampGray
    case stampRed
}
