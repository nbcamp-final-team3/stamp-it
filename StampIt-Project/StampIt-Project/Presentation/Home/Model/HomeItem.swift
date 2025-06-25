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
    case memberFilter
    case memberMission
}

extension HomeSection {
    var placeholderText: String {
        switch self {
        case .myMission:
            return "아직 부여된 미션이 없어요!"
        case .memberMission:
            return "아직 전달한 미션이 없어요!"
        default:
            return ""
        }
    }
}

enum HomeItem: Hashable {
    case member(HomeMember)
    case myMission(HomeMyMission)
    case memberFilter(nickname: String)
    case memberMission(HomeMemberMission)
    case placeholder(HomeSection)

    var member: HomeMember? {
        if case .member(let member) = self {
            return member
        } else {
            return nil
        }
    }

    var myMission: HomeMyMission? {
        if case .myMission(let mission) = self {
            return mission
        } else {
            return nil
        }
    }

    var memberFilter: String? {
        if case .memberFilter(let nickname) = self {
            return nickname
        } else {
            return nil
        }
    }

    var memberMission: HomeMemberMission? {
        if case .memberMission(let mission) = self {
            return mission
        } else {
            return nil
        }
    }

    var placeholder: HomeSection? {
        if case .placeholder(let section) = self {
            return section
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

    func makeCopyCompleted() -> HomeMyMission {
        .init(
            missionID: self.missionID,
            title: self.title,
            category: self.category,
            dueDate: self.dueDate,
            assigner: self.assigner,
            isNew: self.isNew,
            isOverdue: self.isOverdue,
            status: .completed
        )
    }
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
