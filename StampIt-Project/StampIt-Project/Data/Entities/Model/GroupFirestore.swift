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
    let inviteCodeCreateAt: Timestamp?
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
            inviteCode: self.inviteCode,
            nameChangedAt: self.nameChangedAt.dateValue()
        )
    }
}

extension Group {
    func toFirestoreModel(groupName: String, inviteCode: String) -> GroupFirestore {
        return GroupFirestore(
            groupId: self.groupID,
            name: groupName,
            leaderId: self.leaderID,
            inviteCode: inviteCode,
            inviteCodeCreateAt: Timestamp(date: Date()),
            nameChangedAt: Timestamp(date: self.nameChangedAt),
            createdAt: Timestamp(date: Date())
        )
    }
}

extension Invite {
    /// GroupFirestore에서 Invitation 도메인 모델 생성
    static func fromGroupFirestore(_ group: GroupFirestore) -> Invite {
        return Invite(
            inviteCode: group.inviteCode,
            groupId: group.groupId,
            groupName: group.name,
            invitedBy: group.leaderId,
            createdAt: group.inviteCodeCreateAt?.dateValue() ?? Date()
        )
    }
}
