//
//  Group.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/5/25.
//

import Foundation

struct Group {
    let groupID: String
    let members: [Member]
    let leaderID: String
    let nameChangedAt: Date
    
    // 추가 필드 (Firestore 매핑용)
    let name: String
    let createdAt: Date
    
    init(groupID: String, members: [Member] = [], leaderID: String,
         nameChangedAt: Date, name: String, createdAt: Date = Date()) {
        self.groupID = groupID
        self.members = members
        self.leaderID = leaderID
        self.nameChangedAt = nameChangedAt
        self.name = name
        self.createdAt = createdAt
    }
}

