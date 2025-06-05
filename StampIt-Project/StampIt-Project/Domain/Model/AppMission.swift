//
//  AppMission.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation

struct AppMission {
    let missionID: String
    let title: String
    let category: String
    let missionType: String
    let isActive: Bool
    
    init(missionID: String, title: String, category: String,
         missionType: String, isActive: Bool = true) {
        self.missionID = missionID
        self.title = title
        self.category = category
        self.missionType = missionType
        self.isActive = isActive
    }
}
