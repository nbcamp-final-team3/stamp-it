//
//  MissionFirestore.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore

struct MissionFirestore: Codable {
    let missionId: String
    let groupId: String
    let title: String
    let assignedBy: String          // 미션 준 사람
    let assignedTo: String          // 미션 받은 사람
    let createDate: Timestamp       // 미션 준 날짜
    let dueDate: Timestamp          // 미션 끝나는 날짜
    let category: String            // TODO: 리팩토링 컬렉션 필드에 없음
    let status: String              // "assigned", "completed", "failed"
    let missionType: String         // "app", "custom"
    
    var documentID: String {
        return missionId
    }
}

// MARK: - Domain Model 변환
extension MissionFirestore {
    func toDomainModel() -> Mission {
        return Mission(
            missionID: self.missionId,
            title: self.title,
            assignedTo: self.assignedTo,
            assignedBy: self.assignedBy,
            createDate: self.createDate.dateValue(),
            dueDate: self.dueDate.dateValue(),
            status: MissionStatus(rawValue: self.status)!,
            imageURL: "", // TODO: imageName으로 변경 예정
            category: MissionCategory(rawValue: self.category)!
        )
    }
}

// MARK: - 상태 enum
extension MissionFirestore {
    enum Status: String, CaseIterable {
        case assigned = "assigned"
        case completed = "completed"
        case failed = "failed"
    }
    
    enum MissionType: String, CaseIterable {
        case app = "app"
        case custom = "custom"
    }
}
