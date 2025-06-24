//
//  HomeSection.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation

enum HomeSection: Hashable, CaseIterable {
    case ranking
    case myMission
    case memberMission
}

extension HomeSection {
    var placeholderText: String? {
        switch self {
        case .ranking:
            return nil
        case .myMission:
            return "아직 부여된 미션이 없어요!"
        case .memberMission:
            return "아직 전달한 미션이 없어요!"
        }
    }
}

enum HomeItem: Hashable {
    case member(HomeMember)
    case myMission(HomeMyMission)
    case memberMission(HomeMemberMission)
    case placeholder(HomeSection)

    var member: HomeMember? {
        if case .member(let member) = self {
            return member
        } else {
            return nil
        }
    }

    var received: HomeMyMission? {
        if case .myMission(let mission) = self {
            return mission
        } else {
            return nil
        }
    }

    var sended: HomeMemberMission? {
        if case .memberMission(let mission) = self {
            return mission
        } else {
            return nil
        }
    }
}

struct HomeMember: Hashable {
    let memberID: String
    let nickname: String
    let stickerCount: String
    let rank: Int
    let profileImage: String?
}

struct HomeMyMission: Hashable {
    let missionID: String
    let title: String
    let category: MissionCategory
    let dueDate: String
    let assigner: String
    let isNew: Bool?
    let isOverdue: Bool
    let status: MissionStatus
}

struct HomeMemberMission: Hashable {
    let missionID: String
    let title: String
    let category: MissionCategory
    let dueDate: String
    let assignee: String
    let status: MissionStatus
    let isOverdue: Bool
    let daysLeft: String
}
