//
//  MemberMissionItem.swift
//  StampIt-Project
//
//  Created by daeun on 6/17/25.
//

import Foundation

enum MemberMissionSection: Hashable, CaseIterable {
    case mission
}

enum MemberMissionItem: Hashable {
    case mission(HomeSendedMission)

    var mission: HomeSendedMission? {
        if case .mission(let mission) = self {
            return mission
        } else {
            return nil
        }
    }
}
