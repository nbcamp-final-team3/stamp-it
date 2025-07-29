//
//  Notice.swift
//  StampIt-Project
//
//  Created by 윤주형 on 7/8/25.
//

import Foundation

struct Notice {
    let noticeId: String
    let title: String
    let description: String
    let category: NoticeCategory
    let createdAt: Date
    let isRead: Bool
}

enum NoticeCategory: String {
    case newMission      // 새로운 미션 알림
    case missionRequest   // 미션 조르기 알림
    case member          // 멤버 관련 알림
    // ...추가 케이스
    case unknown
}
