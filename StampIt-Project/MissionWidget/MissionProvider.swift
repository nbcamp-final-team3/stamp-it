//
//  MissionProvider.swift
//  StampIt-Project
//
//  Created by 이부용 on 8/8/25.
//

import WidgetKit

struct MissionTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MissionEntry {
        MissionEntry(date: Date(), missions: fetchMissions())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MissionEntry) -> ()) {
        let entry = MissionEntry(date: Date(), missions: fetchMissions())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let missions = fetchMissions()
        let entry = MissionEntry(date: Date(), missions: missions)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func fetchMissions() -> [MissionWidgetUI] {
        let defaults = UserDefaults(suiteName: "group.com.by.Family-Stamp-It-Widget-")
        if let data = defaults?.data(forKey: "missions"),
           let missions = try? JSONDecoder().decode([MissionWidgetUI].self, from: data) {
            print("미션 데이터: \(missions)")
        } else {
            print("미션 데이터 없음!")
        }
        guard let data = defaults?.data(forKey: "missions") else { return [] }
        let decoder = JSONDecoder()
        if let missions = try? decoder.decode([MissionWidgetUI].self, from: data) {
            return missions
        }
        return []
    }
}
