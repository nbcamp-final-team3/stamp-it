//
//  MyMissionItem.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation

enum MyMissionSection: Hashable, CaseIterable {
    case mission
}

enum MyMissionItem: Hashable {
    case mission(HomeMyMission)

    var mission: HomeMyMission? {
        if case .mission(let homeMyMission) = self {
            return homeMyMission
        } else {
            return nil
        }
    }
}
