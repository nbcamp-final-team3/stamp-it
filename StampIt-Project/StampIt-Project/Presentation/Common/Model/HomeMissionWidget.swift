//
//  MissionWidgetUI.swift
//  StampIt-Project
//
//  Created by 이부용 on 8/8/25.
//

import Foundation

struct HomeMissionWidget: Codable, Identifiable {
    let id: String
    let title: String
    let fromLabel: String
    let duration: String
    let isNew: Bool
    let category: MissionCategory
}

extension HomeMissionWidget {
    init(from ui: StampBoardMission) {
        self.id = ui.missionID
        self.title = ui.title
        self.category = ui.category
        self.fromLabel = ui.nickname
        self.duration = ui.dueDate
        self.isNew = false
    }
}
