//
//  SampleMission.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/4/25.
//

import Foundation

struct SampleMission: Decodable {
    let missionId: String
    let title: String
    let description: String?
    let category: MissionCategory
    
    enum CodingKeys: String, CodingKey {
        case missionId, title, description, category
    }
    
    // 커스텀 init으로 category를 매핑
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        missionId = try container.decode(String.self, forKey: .missionId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        let categoryString = try container.decode(String.self, forKey: .category)
        switch categoryString {
        case "집안일":
            category = .chore
        case "가족소통":
            category = .communication
        case "건강운동":
            category = .health
        case "독서학습":
            category = .learning
        default:
            throw DecodingError.dataCorruptedError(forKey: .category, in: container, debugDescription: "Unknown category: \(categoryString)")
        }
    }
}
