//
//  MissionNotification.swift
//  StampIt-Project
//
//  Created by iOS study on 6/27/25.
//

import Foundation
import UserNotifications

struct MissionNotification {
    let id: String
    let missionID: String
    let title: String
    let body: String
    let assignedBy: String
    let receivedAt: Date
    let mission: Mission
}

enum NotificationType: String {
    case missionAssigned = "mission_assigned"
    case missionCompleted = "mission_completed"
    case missionReminder = "mission_reminder"
}
