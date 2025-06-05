//
//  MemberMapper.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import Firebase

extension Member {
    static func fromFirestore(data: [String: Any]) -> Member? {
        guard let userID = data["userId"] as? String,
              let nickname = data["nickname"] as? String,
              let isLeader = data["isLeader"] as? Bool else {
            return nil
        }
        
        return Member(
            userID: userID,
            nickname: nickname,
            joinedAt: (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date(),
            isLeader: isLeader
        )
    }
    
    func toFirestore() -> [String: Any] {
        return [
            "userId": userID,
            "nickname": nickname,
            "joinedAt": joinedAt,
            "isLeader": isLeader
        ]
    }
}
