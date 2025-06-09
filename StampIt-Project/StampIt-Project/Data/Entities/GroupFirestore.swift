//
//  GroupFirestore.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore

struct GroupFirestore: Codable {
    let groupId: String
    let name: String
    let leaderId: String
    let inviteCode: String
    let nameChangedAt: Timestamp
    let createdAt: Timestamp
    
    var documentID: String {
        return groupId
    }
}

// MARK: - Domain Model 변환
extension GroupFirestore {
    func toDomainModel(members: [Member]) -> Group {
        return Group(
            groupID: self.groupId,
            members: members,
            leaderID: self.leaderId,
            nameChangedAt: self.nameChangedAt.dateValue()
        )
    }
}
