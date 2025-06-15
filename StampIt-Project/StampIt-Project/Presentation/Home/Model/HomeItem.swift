//
//  HomeSection.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation

enum HomeSection: Hashable, CaseIterable {
    case ranking
    case receivedMission
    case sendedMission
}

extension HomeSection {
    var placeholderText: String? {
        switch self {
        case .ranking:
            return nil
        case .receivedMission:
            return "아직 부여된 미션이 없어요!"
        case .sendedMission:
            return "아직 전달한 미션이 없어요!"
        }
    }
}

enum HomeItem: Hashable {
    case member(HomeMember)
    case received(HomeReceivedMission)
    case sended(HomeSendedMission)
    case placeholder(HomeSection)

    var member: HomeMember? {
        if case .member(let member) = self {
            return member
        } else {
            return nil
        }
    }

    var received: HomeReceivedMission? {
        if case .received(let mission) = self {
            return mission
        } else {
            return nil
        }
    }

    var sended: HomeSendedMission? {
        if case .sended(let mission) = self {
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
    let profileImageURL: String?
}

struct HomeReceivedMission: Hashable {
    let missionID: String
    let title: String
    let category: MissionCategory
    let dueDate: String
    let assigner: String
    let isNew: Bool?
}

struct HomeSendedMission: Hashable {
    let missionID: String
    let title: String
    let category: MissionCategory
    let dueDate: String
    let assignee: String
    let status: MissionStatus
    let isOverdue: Bool
    let daysLeft: String
}
