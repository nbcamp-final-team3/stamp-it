//
//  WidgetMissionEntity.swift
//  StampIt-Project
//
//  Created by 이부용 on 8/8/25.
//

import WidgetKit

struct MissionEntry: TimelineEntry {
    let date: Date
    let missions: [MissionWidgetUI]
}

struct Mission {
    let id: String
    let title: String
    let fromLabel: String
    let duration: String
    let isNew: Bool
    let category: MissionCategory
}
