//
//  UserFirestore.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore

struct UserFirestore: Codable {
    let userId: String
    let nickname: String
    let email: String
    let profileImage: String?        // nullable
    let groupId: String
    let nicknameChangedAt: Timestamp
    let createdAt: Timestamp
    
    // Firestore 문서 ID를 위한 편의 프로퍼티
    var documentID: String {
        return userId
    }
}

// MARK: - Domain Model 변환
extension UserFirestore {
    func toDomainModel() -> User {
        return User(
            userID: self.userId,
            nickname: self.nickname,
            profileImageURL: self.profileImage,
            boards: [],  // 별도 로직에서 처리
            groupID: self.groupId,
            groupName: "", // 별도 조회 필요
            isLeader: false, // 별도 조회 필요
            joinedGroupAt: self.createdAt.dateValue()
        )
    }
}
