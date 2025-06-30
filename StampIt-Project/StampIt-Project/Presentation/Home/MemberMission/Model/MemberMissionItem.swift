//
//  MemberMissionItem.swift
//  StampIt-Project
//
//  Created by daeun on 6/17/25.
//

import Foundation

enum MemberMissionSection: Hashable, CaseIterable {
    case filter
    case mission
}

enum MemberMissionItem: Hashable {
    case member(HomeMember)
    case mission(HomeMemberMission)

    var mission: HomeMemberMission? {
        if case .mission(let mission) = self {
            return mission
        } else {
            return nil
        }
    }
}
