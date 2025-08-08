//
//  MissionProvider.swift
//  StampIt-Project
//
//  Created by 이부용 on 8/8/25.
//

import WidgetKit

struct MissionTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MissionEntry {
        MissionEntry(date: Date(), missions: getSampleMissions())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MissionEntry) -> ()) {
        let entry = MissionEntry(date: Date(), missions: getSampleMissions())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let missions = fetchMissions().isEmpty ? getSampleMissions() : fetchMissions()
        let entry = MissionEntry(date: Date(), missions: missions)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func fetchMissions() -> [Mission] {
        // TODO: 실제 API 호출 로직으로 변경 예정
        return []
    }
    
    private func getSampleMissions() -> [Mission] {
        return [
            Mission(
                id: "1",
                title: "미션내용입니다미션내용미션내용미션내용미션내용",
                fromLabel: "from.label",
                duration: "~기간",
                isNew: true,
                category: .chore
            ),
            Mission(
                id: "2",
                title: "미션내용입니다미션내용미션내용미션내용미션내용",
                fromLabel: "from.label",
                duration: "~기간",
                isNew: true,
                category: .health
            )
        ]
    }
}
