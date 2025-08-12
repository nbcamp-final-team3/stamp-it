//
//  WidgetMissionManager.swift
//  StampIt-Project
//
//  Created by 이부용 on 8/8/25.
//

import Foundation

final class WidgetMissionManager {
    static let shared = WidgetMissionManager()
    private let suiteName = "group.com.by.Family-Stamp-It-Widget-AppGroups"
    private let key = "missions"
    
    private init() {}
    
    func save(missions: [HomeMissionWidget]) {
        print("위젯 데이터 저장 시도: \(missions.count)개")
        print("App Group ID: \(suiteName)")
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(missions) {
            let defaults = UserDefaults(suiteName: suiteName)
            defaults?.set(data, forKey: key)
            defaults?.synchronize() // 강제 동기화
            
            // 저장 확인
            if let savedData = defaults?.data(forKey: key) {
                print("데이터 저장 성공: \(savedData.count) bytes")
                
                // 디코딩 테스트
                if let savedMissions = try? JSONDecoder().decode([HomeMissionWidget].self, from: savedData) {
                    print("저장된 미션: \(savedMissions.count)개")
                    for mission in savedMissions {
                        print("  - \(mission.title)")
                    }
                } else {
                    print("디코딩 실패")
                }
            } else {
                print("데이터 저장 실패")
            }
        } else {
            print("인코딩 실패")
        }
    }
}
