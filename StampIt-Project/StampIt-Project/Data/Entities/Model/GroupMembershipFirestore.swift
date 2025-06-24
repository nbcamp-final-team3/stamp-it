//
//  GroupMembershipFirestore.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation
import FirebaseFirestore

struct GroupMembershipFirestore: Codable {
    let membershipId: String          // PK (문서ID, "{groupId}_{userId}")
    let groupId: String
    let userId: String
    let nickname: String              // 캐싱된 닉네임
    let profileImage: String?         // 캐싱된 프로필 이미지
    let isLeader: Bool
    let joinedAt: Timestamp

    var documentID: String { membershipId }
}

// MARK: - Domain Model 변환
extension GroupMembershipFirestore {
    func toDomainModel() -> Member {
        return Member(
            userID: self.userId,
            nickname: self.nickname,
            profileImage: self.profileImage,
            monthSticker: 0,  // 별도 계산 필요
            joinedAt: self.joinedAt.dateValue(),
            isLeader: self.isLeader
        )
    }
}

extension Member {
    func toMembershipFirestoreModel(groupId: String) -> GroupMembershipFirestore {
        return GroupMembershipFirestore(
            membershipId: "\(groupId)_\(self.userID)",  //{groupId}_{userId} 형태 꼭!!!!
            groupId: groupId,
            userId: self.userID,
            nickname: self.nickname,
            profileImage: self.profileImage,
            isLeader: self.isLeader,
            joinedAt: Timestamp(date: self.joinedAt)
        )
    }
}
