//
//  InviteFirestore.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore

struct InviteFirestore: Codable {
    let inviteCode: String
    let groupId: String
    let createdBy: String
    let createdAt: Timestamp
    let expiredAt: Timestamp?       // nullable
    
    var documentID: String {
        return inviteCode
    }
}

// MARK: - Domain Model 변환
extension InviteFirestore {
    func toDomainModel() -> Invitation {
        return Invitation(
            groupID: self.groupId,
            createdBy: self.createdBy,
            expiredAt: self.expiredAt?.dateValue() ?? Date.distantFuture
        )
    }
}
