//
//  UserMapper.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import Firebase

extension User {
    /// Firestore -> Domain Entity
    static func fromFirestore(data: [String: Any]) -> User? {
        guard let userID = data["userId"] as? String,
              let nickname = data["nickname"] as? String,
              let groupID = data["groupId"] as? String else {
            return nil
        }
        
        return User(
            userID: userID,
            nickname: nickname,
            profileImageURL: data["profileImage"] as? String,
            boards: [], // 별도 로드
            groupID: groupID,
            groupName: "", // 별도 로드 필요
            isLeader: false, // 별도 확인 필요
            joinedGroupAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            email: data["email"] as? String,
            nicknameChangedAt: (data["nicknameChangedAt"] as? Timestamp)?.dateValue(),
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    /// Domain Entity → Firestore
    func toFirestore() -> [String: Any] {
        return [
            "userId": userID,
            "nickname": nickname,
            "email": email ?? "",
            "profileImage": profileImageURL ?? "",
            "groupId": groupID,
            "nicknameChangedAt": nicknameChangedAt ?? Date(),
            "createdAt": createdAt
        ]
    }
}
