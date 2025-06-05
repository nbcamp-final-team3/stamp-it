//
//  Mission.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation

struct Mission {
    let missionID: String
    let title: String
    let assignedBy: String
    let assignedTo: String
    let createDate: Date
    let dueDate: Date
    let status: MissionStatus
    let createdAt: Date
    
    init(missionID: String, title: String, assignedBy: String, assignedTo: String,
         createDate: Date = Date(), dueDate: Date, status: MissionStatus = .assigned,
         createdAt: Date = Date()) {
        self.missionID = missionID
        self.title = title
        self.assignedBy = assignedBy
        self.assignedTo = assignedTo
        self.createDate = createDate
        self.dueDate = dueDate
        self.status = status
        self.createdAt = createdAt
    }
}

enum MissionStatus: String, CaseIterable {
    case assigned = "assigned"
    case completed = "completed"
    case failed = "failed"
}
