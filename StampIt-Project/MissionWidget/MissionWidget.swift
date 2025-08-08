//
//  MissionWidget.swift
//  MissionWidget
//
//  Created by 이부용 on 8/8/25.
//

import WidgetKit
import SwiftUI

struct MissionWidget: Widget {
    let kind: String = "MissionWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MissionTimelineProvider()) { entry in
            MissionWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("내 미션")
        .description("오늘의 미션을 확인하세요")
        .supportedFamilies([.systemMedium])
    }
}
