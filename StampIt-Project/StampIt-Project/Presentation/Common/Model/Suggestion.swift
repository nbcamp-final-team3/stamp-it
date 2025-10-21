//
//  Suggestion.swift
//  StampIt-Project
//
//  Created by 권순욱 on 9/6/25.
//

import Foundation
import FoundationModels

struct Suggestion {
    let title: String
    let source: SuggestionSource
    
    enum SuggestionSource {
        case history
        case AI
    }
}

@available(iOS 26.0, *)
@Generable
struct AISuggestion {
    @Guide(.count(3))
    let results: [GeneratedMission]
}

@available(iOS 26.0, *)
@Generable
struct GeneratedMission {
    @Guide(description: "Title of the mission proposed to the user")
    let title: String
    // TODO: 아래 프라퍼티도 구현해야 제너레이팅 결과 품질을 높일 수 있을 것 같음.
    // let assignee: String
    // let dueDate: Date
}
