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
    let groupId: String
    let profileImage: String?
    let nicknameChangedAt: Timestamp
    let createdAt: Timestamp
    
    var documentID: String { return userId }
}

// MARK: - Domain Model 변환 (새 구조 적용)
extension UserFirestore {
    
    /// 기본 도메인 모델 변환 (그룹 정보 없이)
    func toDomainModel() -> StampIt_Project.User {
        return StampIt_Project.User(
            userID: self.userId,
            nickname: self.nickname,
            profileImage: self.profileImage,
            boards: [],
            groupID: self.groupId,
            groupName: "", // 별도 조회 필요 (GroupManager)
            isLeader: false, // 별도 조회 필요 (GroupMembershipManager)
            joinedGroupAt: self.createdAt.dateValue()
        )
    }
    
    /// 그룹 정보와 함께 도메인 모델 변환 (Repository에서 사용)
       func toDomainModel(
           groupName: String,
           isLeader: Bool,
           boards: [StickerBoard] = [],
           joinedGroupAt: Date? = nil
       ) -> StampIt_Project.User {
           let domainUser = StampIt_Project.User(
               userID: self.userId,
               nickname: self.nickname,
               profileImage: self.profileImage,
               boards: boards,
               groupID: self.groupId,
               groupName: groupName,
               isLeader: isLeader,
               joinedGroupAt: joinedGroupAt ?? self.createdAt.dateValue()
           )
           return domainUser
       }
    
    /// 특정 그룹에서의 사용자 정보 변환 (그룹별 정보 포함)
    func toDomainModelForGroup(
        groupMembership: GroupMembershipFirestore,  // 새로운 구조 활용
        groupName: String,
        boards: [StickerBoard] = []
    ) -> StampIt_Project.User {
        return StampIt_Project.User(
            userID: self.userId,
            nickname: self.nickname,
            profileImage: self.profileImage,
            boards: boards,
            groupID: groupMembership.groupId,
            groupName: groupName,
            isLeader: groupMembership.isLeader,
            joinedGroupAt: groupMembership.joinedAt.dateValue()
        )
    }
}

// MARK: - Domain → Infrastructure 변환 메서드 (수정)
extension User {
    
    /// 기본 Firestore 모델 변환 (사용자 생성 시)
    func toFirestoreModel() -> UserFirestore {
        return UserFirestore(
            userId: self.userID,
            nickname: self.nickname,
            groupId: self.groupID,
            profileImage: self.profileImage,
            nicknameChangedAt: Timestamp(date: Date()), // 현재 시간으로 설정
            createdAt: Timestamp(date: Date())
        )
    }
    
    /// 업데이트용 Firestore 모델 변환 (기존 생성일 유지)
    func toFirestoreModel(preserveCreatedAt: Date) -> UserFirestore {
        return UserFirestore(
            userId: self.userID,
            nickname: self.nickname,
            groupId: self.groupID,
            profileImage: self.profileImage,
            nicknameChangedAt: Timestamp(date: Date()),
            createdAt: Timestamp(date: preserveCreatedAt), // 기존 생성일 유지
        )
    }
}
