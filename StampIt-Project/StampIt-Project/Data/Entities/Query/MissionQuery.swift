//
//  MissionQuery.swift
//  StampIt-Project
//
//  Created by iOS study on 6/24/25.
//

import Foundation

// MARK: - MissionQuery 정의
struct MissionQuery {
    let missionIds: [String]?
    let groupIds: [String]?
    let assigneeIds: [String]?
    let assignerIds: [String]?
    let isCompleted: Bool?
    let createdAfter: Date?
    let dueDate: Date?
    let orderBy: QueryOrder?
    let limit: Int?
    
    static func byGroup(_ groupId: String) -> MissionQuery {
        return MissionQuery(missionIds: nil, groupIds: [groupId], assigneeIds: nil, assignerIds: nil, isCompleted: nil, createdAfter: nil, dueDate: nil, orderBy: nil, limit: nil)
    }
    
    static func byAssignee(_ assigneeId: String, groupId: String) -> MissionQuery {
        return MissionQuery(missionIds: nil, groupIds: [groupId], assigneeIds: [assigneeId], assignerIds: nil, isCompleted: nil, createdAfter: nil, dueDate: nil, orderBy: nil, limit: nil)
    }
    
    static func byAssigner(_ assignerId: String, groupId: String) -> MissionQuery {
        return MissionQuery(missionIds: nil, groupIds: [groupId], assigneeIds: nil, assignerIds: [assignerId], isCompleted: nil, createdAfter: nil, dueDate: nil, orderBy: nil, limit: nil)
    }
}
