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

enum NotificationType {
    case missionReceived
    case missionCompleted
    case missionReminder
}
