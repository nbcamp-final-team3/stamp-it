//
//  GroupMapper.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import Firebase

extension Group {
    static func fromFirestore(data: [String: Any]) -> Group? {
        guard let groupID = data["groupId"] as? String,
              let name = data["name"] as? String,
              let leaderID = data["leaderId"] as? String else {
            return nil
        }
        
        return Group(
            groupID: groupID,
            members: [], //별도 로드
            leaderID: leaderID,
            nameChangedAt: (data["nameChangedAt"] as? Timestamp)?.dateValue() ?? Date(),
            name: name,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
    
    func toFirestoreData() -> [String: Any] {
        return [
            "groupId": groupID,
            "name": name,
            "leaderId": leaderID,
            "nameChangedAt": nameChangedAt,
            "createdAt": createdAt
        ]
    }
}
