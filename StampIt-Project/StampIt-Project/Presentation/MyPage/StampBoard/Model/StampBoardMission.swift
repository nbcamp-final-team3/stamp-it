//
//  StampBoardMission.swift
//  StampIt-Project
//
//  Created by kingj on 7/2/25.
//

import Foundation

struct StampBoardMission: Equatable {
    let missionID: String
    let title: String
    var nickname: String
    let dueDate: String
    let category: MissionCategory
}
