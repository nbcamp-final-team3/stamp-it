//
//  Member.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/5/25.
//

import Foundation

struct Member {
    let userID: String
    let nickname: String
    let profileImage: String?
    let monthSticker: Int
    let joinedAt: Date
    let isLeader: Bool
}

// MARK: - Member to User 변환
extension Member {
    func toUser(groupId: String, groupName: String) -> User {
        return User(
            userID: self.userID,
            nickname: self.nickname,
            profileImage: self.profileImage,
            boards: [], // 빈 배열로 초기화
            groupID: groupId,
            groupName: groupName,
            isLeader: self.isLeader,
            joinedGroupAt: self.joinedAt
        )
    }
}
