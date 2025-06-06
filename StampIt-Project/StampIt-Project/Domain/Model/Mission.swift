//
//  Mission.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation

struct Mission {
    let missionID: String
    let title: String
    let asignedTo: String
    let asignedBy: String
    let dueDate: Date
    let status: MissionStatus
    let imageURL: String
}
