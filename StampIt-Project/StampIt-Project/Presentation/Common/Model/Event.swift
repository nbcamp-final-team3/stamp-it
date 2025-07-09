//
//  Event.swift
//  StampIt-Project
//
//  Created by 권순욱 on 7/6/25.
//

import Foundation

enum Event {
    case tapMission
    case assignMission
    
    var relevance: Double {
        switch self {
        case .tapMission: 0.1
        case .assignMission: 0.4
        }
    }
}
