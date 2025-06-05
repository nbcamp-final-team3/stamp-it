//
//  Invite.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/5/25.
//

import Foundation

struct Invitation {
    let groupID: String
    let createdBy: String
    let expiredAt: Date
    
    // 추가 필드 (Firestore 매핑용)
    let inviteCode: String
    let createdAt: Date
    
    init(groupID: String, createdBy: String, expiredAt: Date,
         inviteCode: String, createdAt: Date = Date()) {
        self.groupID = groupID
        self.createdBy = createdBy
        self.expiredAt = expiredAt
        self.inviteCode = inviteCode
        self.createdAt = createdAt
    }
}
