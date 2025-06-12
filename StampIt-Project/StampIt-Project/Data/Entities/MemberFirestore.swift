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
            joinedAt: self.joinedAt.dateValue(),
            isLeader: self.isLeader
        )
    }
}
