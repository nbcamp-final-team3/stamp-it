//
//  AnalyticsManager.swift
//  StampIt-Project
//
//  Created by 이부용 on 8/7/25.
//

import FirebaseAnalytics

protocol AnalyticsManagerProtocol {
    func logScreenView(screenName: String)
    func logClickEvent(screen: String, position: String, coordinates: CGPoint?)
    func logScreenDuration(screen: String, duration: TimeInterval)
    func logInviteCodeShare(screen: String)
}

final class AnalyticsManager: AnalyticsManagerProtocol {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // 스크린 타임 기록
    func logScreenView(screenName: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // 클릭 위치 기록
    func logClickEvent(screen: String, position: String, coordinates: CGPoint? = nil) {
        var parameters: [String: Any] = [
            "screen": screen,
            "position": position,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let coords = coordinates {
            parameters["tap_x"] = coords.x
            parameters["tap_y"] = coords.y
        }
        
        Analytics.logEvent("click_event", parameters: parameters)
    }
    
    // 머문 시간 기록
    func logScreenDuration(screen: String, duration: TimeInterval) {
        Analytics.logEvent("screen_duration", parameters: [
            "screen": screen,
            "duration_seconds": duration,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // TODO: 추후에 logEvent만 다르게 받고 버튼 집계 시 하나의 메서드로 통일할 예정
    // 초대코드 공유하기 버튼 집계
    func logInviteCodeShare(screen: String) {
        Analytics.logEvent("invite_code_share", parameters: [
            "screen": screen,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // 미션 조르기 사용자 비율 집계
    func logRequestMission(screen: String) {
        Analytics.logEvent("request_mission", parameters: [
            "screen": screen,
            "timestamp": Date().timeIntervalSince1970
        ])
    }

    // 미션 전달하기 사용자 비율 집계
    func logSendMission(screen: String) {
        Analytics.logEvent("send_mission", parameters: [
            "screen": screen,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}
