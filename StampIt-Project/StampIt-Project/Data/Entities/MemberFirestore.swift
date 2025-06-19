//
//  MemberFirestore.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore

struct MemberFirestore: Codable {
    let userId: String
    let nickname: String
    let joinedAt: Timestamp
    let isLeader: Bool
    let profileImage: String?

    var documentID: String {
        return userId
    }
}

// MARK: - Domain Model 변환
extension MemberFirestore {
    func toDomainModel() -> Member {
        return Member(
            userID: self.userId,
            nickname: self.nickname,
            profileImage: self.profileImage,
            monthSticker: 0,
            joinedAt: self.joinedAt.dateValue(),
            isLeader: self.isLeader
        )
    }
}

extension Member {
    func toFirestoreModel() -> MemberFirestore {
        return MemberFirestore(
            userId: self.userID,
            nickname: self.nickname,
            joinedAt: Timestamp(date: self.joinedAt),
            isLeader: self.isLeader,
            profileImage: self.profileImage
        )
    }
}
