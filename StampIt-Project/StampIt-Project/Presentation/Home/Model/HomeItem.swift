//
//  HomeSection.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation


enum HomeItem: Hashable {
    case member(HomeMember)
    case received(HomeReceivedMission)
    case sended(HomeSendedMission)

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
    let isNew: Bool
}

struct HomeSendedMission: Hashable {
    let missionID: String
    let title: String
    let category: MissionCategory
    let dueDate: String
    let assignee: String
    let status: String
}
