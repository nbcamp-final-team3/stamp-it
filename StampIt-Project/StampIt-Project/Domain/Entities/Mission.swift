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

extension Mission {
    func toPresentation() -> MissionUI {
        MissionUI(
            missionID: self.missionID,
            title: self.title,
            assignedBy: self.assignedBy,
            dueDate: formattedString(with: self.dueDate),
            category: self.category
        )
    }
    
    func formattedString(with date: Date) -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyy년 M월 d일"
        
        let dateString = format.string(from: date)
        return dateString
    }
}
