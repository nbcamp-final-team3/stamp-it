//
//  MyMissionItem.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation

enum MyMissionSection: Hashable, CaseIterable {
    case filter
    case mission
}

enum MyMissionItem: Hashable {
    case status(MissionStatusFilter)
    case mission(HomeMyMission)

    var status: MissionStatusFilter? {
        if case .status(let status) = self {
            return status
        } else {
            return nil
        }
    }

    var mission: HomeMyMission? {
        if case .mission(let mission) = self {
            return mission
        } else {
            return nil
        }
    }
}

struct MissionStatusFilter: Hashable {
    let status: MissionStatus?
    let count: Int

    private var filterTitle: String {
        switch status {
        case .none:
            "전체보기"
        case .assigned:
            "진행중인 미션"
        case .completed:
            "완료한 미션"
        case .failed:
            "기간 만료된 미션"
        }
    }

    /// 셀에 표시할 텍스트
    var displayTitle: String {
        return "\(filterTitle)(\(count))"
    }
}
