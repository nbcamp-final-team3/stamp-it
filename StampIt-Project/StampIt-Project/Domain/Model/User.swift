//
//  User.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/5/25.
//

import Foundation

struct User {
    let userID: String
    let nickname: String
    let profileImageURL: String?
    let boards: [StickerBoard]
    let groupID: String
    let groupName: String
    let isLeader: Bool
    let joinedGroupAt: Date
}
