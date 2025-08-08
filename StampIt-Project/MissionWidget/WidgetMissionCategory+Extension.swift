//
//  WidgetMissionCategory+Extension.swift
//  StampIt-Project
//
//  Created by 이부용 on 8/8/25.
//

import SwiftUI

extension MissionCategory {
    var widgetImage: Image {
        let imageName: String
        switch self {
            case .chore: imageName = "chore"
            case .communication: imageName = "communication"
            case .health: imageName = "health"
            case .learning: imageName = "learning"
            case .custom: imageName = "custom"
        }
        return Image(imageName)
    }
}
