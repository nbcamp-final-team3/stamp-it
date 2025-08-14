//
//  MissionCategory.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import Foundation

enum MissionCategory: String, CaseIterable, Codable {
    case chore
    case communication
    case health
    case learning
    case custom
}

// MARK: - Image Name Protocol
extension MissionCategory {
    /// 이미지 파일명을 반환하는 연산 프로퍼티
    var imageName: String {
        switch self {
        case .chore: return "chore"
        case .communication: return "communication"
        case .health: return "health"
        case .learning: return "learning"
        case .custom: return "custom"
        }
    }
}
