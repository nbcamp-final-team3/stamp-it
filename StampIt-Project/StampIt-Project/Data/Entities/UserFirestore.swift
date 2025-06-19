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
    func toDomainModel() -> StampIt_Project.User {
        return StampIt_Project.User(
            userID: self.userId,
            nickname: self.nickname,
            profileImage: self.profileImage,
            boards: [],  // 별도 로직에서 처리
            groupID: self.groupId,
            groupName: "", // 별도 조회 필요
            isLeader: false, // 별도 조회 필요
            joinedGroupAt: self.createdAt.dateValue()
        )
    }
    
    /// 그룹 정보와 함께 도메인 모델 변환 (AuthRepo에서 사용)
    func toDomainModel(
        groupName: String,
        isLeader: Bool
    ) -> StampIt_Project.User {
        return StampIt_Project.User(
            userID: self.userId,
            nickname: self.nickname,
            profileImage: self.profileImage,
            boards: [],
            groupID: self.groupId,
            groupName: groupName,
            isLeader: isLeader,
            joinedGroupAt: self.createdAt.dateValue()
        )
    }
}

// Domain → Infrastructure 변환 메서드
extension User {
    func toFirestoreModel() -> UserFirestore {
        return UserFirestore(
            userId: self.userID,
            nickname: self.nickname,
            profileImage: self.profileImageURL,
            groupId: self.groupID,
            nicknameChangedAt: Timestamp(date: Date()), // 현재 시간으로 설정
            createdAt: Timestamp(date: self.joinedGroupAt)
        )
    }
}
