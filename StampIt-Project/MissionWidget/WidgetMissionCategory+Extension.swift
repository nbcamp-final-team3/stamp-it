//
//  WidgetMissionCategory+Extension.swift
//  StampIt-Project
//
//  Created by 이부용 on 8/8/25.
//

import SwiftUI

extension MissionCategory {
    var widgetImage: Image {
        switch self {
        case .chore:
            Image("chore")
        case .communication:
            Image("communication")
        case .health:
            Image("health")
        case .learning:
            Image("learning")
        case .custom:
            Image("custom")
        }
    }
}
