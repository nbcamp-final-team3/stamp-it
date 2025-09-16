//
//  MissionData.swift
//  StampIt-Project
//
//  Created by 권순욱 on 8/3/25.
//

import Foundation

struct MissionData {
    let title: String
    let assigneeId: String
    let assigneeNickname: String
    let createDate: Date
    let dueDate: Date
    let category: MissionCategory
}
