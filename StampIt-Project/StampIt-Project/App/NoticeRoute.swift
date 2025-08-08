//
//  NoticeRoute.swift
//  StampIt-Project
//
//  Created by daeun on 8/8/25.
//

import Foundation

enum NoticeRoute {
    case newMission
    case missionRequest
    case member
    case unknown

    init(deepLink urlString: String) {
        let path = urlString.replacingOccurrences(of: "stampit://", with: "")
        let components = path.components(separatedBy: "/")

        let kind = components.first
        switch kind {
        case "newMission": self = .newMission
        case "missionRequest": self = .missionRequest
        case "member": self = .member
        default: self = .unknown
        }
    }
}
