//
//  MissionCategory+Extension.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit

extension MissionCategory {
    var title: String {
        switch self {
        case .chore:
            "집안일"
        case .communication:
            "가족소통"
        case .health:
            "건강운동"
        case .learning:
            "독서학습"
        }
    }

    var image: UIImage {
        switch self {
        case .chore:
                .chore
        case .communication:
                .communication
        case .health:
                .health
        case .learning:
                .learning
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .chore:
                .red100
        case .communication:
                .blue100
        case .health:
                .yellow100
        case .learning:
                .purple100
        }
    }
}
