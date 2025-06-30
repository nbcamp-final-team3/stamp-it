//
//  MemberMissionItem.swift
//  StampIt-Project
//
//  Created by daeun on 6/17/25.
//

import UIKit

enum MemberMissionSection: Hashable, CaseIterable {
    case filter
    case mission
}

enum MemberMissionItem: Hashable {
    case allMember(image: UIImage, title: String) // 전체보기용 아이템
    case member(HomeMember)
    case mission(HomeMemberMission)

    var allMember: (image: UIImage, title: String)? {
        if case .allMember(let image, let title) = self {
            return (image, title)
        } else {
            return nil
        }
    }

    var member: HomeMember? {
        if case .member(let member) = self {
            return member
        } else {
            return nil
        }
    }

    var mission: HomeMemberMission? {
        if case .mission(let mission) = self {
            return mission
        } else {
            return nil
        }
    }
}
