//
//  Suggestion.swift
//  StampIt-Project
//
//  Created by 권순욱 on 9/6/25.
//

import Foundation

struct Suggestion {
    let title: String
    let source: SuggestionSource
    
    enum SuggestionSource {
        case history
        case AI
    }
}
