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
    let title: String
    let assignedBy: String
    let assignedTo: String
    let createDate: Timestamp
    let dueDate: Timestamp
    let category: String
    let status: String              // "assigned", "completed", "failed"
    let missionType: String         // "app", "custom"
    let createdAt: Timestamp
    
    var documentID: String {
        return missionId
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
