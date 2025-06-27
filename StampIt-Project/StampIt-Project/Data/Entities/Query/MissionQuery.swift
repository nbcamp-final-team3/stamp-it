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
    let status: String?
    let createdAfter: Date?
    let dueDate: Date?
    let orderBy: QueryOrder?
    let limit: Int?
    
    static func byGroup(_ groupId: String) -> MissionQuery {
        return MissionQuery(missionIds: nil, groupIds: [groupId], assigneeIds: nil, assignerIds: nil, status: nil, createdAfter: nil, dueDate: nil, orderBy: nil, limit: nil)
    }
    
    static func byAssignee(_ assigneeId: String, groupId: String) -> MissionQuery {
        return MissionQuery(missionIds: nil, groupIds: [groupId], assigneeIds: [assigneeId], assignerIds: nil, status: nil, createdAfter: nil, dueDate: nil, orderBy: nil, limit: nil)
    }
    
    static func byAssigner(_ assignerId: String, groupId: String) -> MissionQuery {
        return MissionQuery(missionIds: nil, groupIds: [groupId], assigneeIds: nil, assignerIds: [assignerId], status: nil, createdAfter: nil, dueDate: nil, orderBy: nil, limit: nil)
    }
    
    /// 특정 사용자의 미완료 미션만 조회
    static func incompleteByAssignee(_ assigneeId: String, groupId: String) -> MissionQuery { return MissionQuery( missionIds: nil, groupIds: [groupId], assigneeIds: [assigneeId], assignerIds: nil, status: MissionStatus.assigned.rawValue, createdAfter: nil, dueDate: nil, orderBy: nil, limit: nil
        )
    }
}
