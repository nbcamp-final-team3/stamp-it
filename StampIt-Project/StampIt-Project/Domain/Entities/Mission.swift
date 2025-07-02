//
//  Mission.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation

struct Mission: Equatable {
    let missionID: String
    let title: String
    let assignedTo: String
    let assignedBy: String
    let createDate: Date
    let dueDate: Date
    let status: MissionStatus
    let imageURL: String
    let category: MissionCategory

    var isOverdue: Bool {
        dueDate.daysFromToday() < 0
    }

    var isNew: Bool {
        let today = Calendar.current.dateComponents([.day], from: Date())
        let created = Calendar.current.dateComponents([.day], from: createDate)
        return today.day == created.day
    }

    func makeCopyCompleted() -> Mission {
        .init(
            missionID: self.missionID,
            title: self.title,
            assignedTo: self.assignedTo,
            assignedBy: self.assignedBy,
            createDate: self.createDate,
            dueDate: self.dueDate,
            status: .completed,
            imageURL: self.imageURL,
            category: self.category,
        )
    }
}
