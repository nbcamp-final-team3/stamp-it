//
//  NoticeCategory+Extension.swift
//  StampIt-Project
//
//  Created by daeun on 7/23/25.
//

import Foundation

extension NoticeCategory {
    var iconImage: UIImage? {
        switch self {
        case .newMission:
                .noticePlus
        case .missionRequest:
                .noticeExclamation
        case .member:
                .noticeMember
        case .unknown:
                nil
        }
    }
}
