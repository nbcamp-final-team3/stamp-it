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
    let joinedGroupAt: Date //Bool>Date 수정
    
    // 추가 필드 (Firestore 매핑용)
    let email: String?
    let nicknameChangedAt: Date?
    let createdAt: Date
    
    init(userID: String, nickname: String, profileImageURL: String? = nil,
         boards: [StickerBoard] = [], groupID: String, groupName: String,
         isLeader: Bool, joinedGroupAt: Date, email: String? = nil,
         nicknameChangedAt: Date? = nil, createdAt: Date = Date()) {
        self.userID = userID
        self.nickname = nickname
        self.profileImageURL = profileImageURL
        self.boards = boards
        self.groupID = groupID
        self.groupName = groupName
        self.isLeader = isLeader
        self.joinedGroupAt = joinedGroupAt
        self.email = email
        self.nicknameChangedAt = nicknameChangedAt
        self.createdAt = createdAt
    }
}
