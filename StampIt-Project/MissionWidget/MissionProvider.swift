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
    
    private func fetchMissions() -> [HomeMissionWidget] {
        let defaults = UserDefaults(suiteName: "group.com.by.Family-Stamp-It-Widget-AppGroups")

        guard let data = defaults?.data(forKey: "missions") else { return [] }
        let decoder = JSONDecoder()
        if let missions = try? decoder.decode([HomeMissionWidget].self, from: data) {
            return missions
        }
        return []
    }
}
