//
//  Sticker.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/5/25.
//

import Foundation

struct Sticker: Hashable {
    let stickerID: UUID
//    let stickerID: String
    let title: String
    let description: String
    let imageURL: String
    let imageType: Stamp // 추가 고려 
    let createdAt: Date
}
