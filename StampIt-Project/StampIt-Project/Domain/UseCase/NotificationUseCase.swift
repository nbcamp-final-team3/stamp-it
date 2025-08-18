//
//  NotificationUseCase.swift
//  StampIt-Project
//
//  Created by 윤주형 on 12/19/25.
//

import Foundation
import RxSwift

protocol NotificationUseCase {
    /// 🎯 그룹 가입 시 새 그룹 멤버들에게 환영 알림 전송
    func sendGroupJoinNotification(
        userId: String,
        userNickname: String,
        toGroupId: String
    ) -> Observable<Void>
    
    /// 🎯 미션 할당 시 관련 멤버들에게 알림 전송
    /// TODO: 다은 네이밍 확인해주세요
    func sendMissionAssignmentNotification(
        missionId: String,
        missionTitle: String,
        UserId: String,
        Nickname: String,
        groupId: String
    ) -> Observable<Void>
}
