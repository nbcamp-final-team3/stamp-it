//
//  NotificationUseCaseImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 12/19/25.
//

import Foundation
import RxSwift

final class NotificationUseCaseImpl: NotificationUseCase {
    
    private let notificationRepository: NotificationRepositoryProtocol
    private let noticeManager: NoticeManagerProtocol
    
    init(notificationRepository: NotificationRepositoryProtocol, noticeManager: NoticeManagerProtocol) {
        self.notificationRepository = notificationRepository
        self.noticeManager = noticeManager
    }
    
    /// 🎯 그룹 가입 시 새 그룹 멤버들에게 환영 알림 전송
    func sendGroupJoinNotification(
        userId: String,
        userNickname: String,
        toGroupId: String
    ) -> Observable<Void> {
        // 1. Firestore에 알림 데이터 저장
        let notice = DataNoticeFirestore(
            noticeId: UUID().uuidString,
            userId: userId,
            title: "새로운 멤버가 가입했습니다",
            description: "\(userNickname)님이 그룹에 가입했습니다!",
            category: "member_joined",
            url: "stamp-it://group/\(toGroupId)",
            isRead: false,
            createdAt: Date()
        )
        
        return noticeManager.create(notice: notice)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 2. FCM 푸시 알림 전송
                return self.notificationRepository.sendDirectFCMNotificationToGroupMembers(
                    groupId: toGroupId,
                    title: "새로운 멤버가 가입했습니다",
                    body: "\(userNickname)님이 그룹에 가입했습니다!",
                    data: [
                        "type": "member_joined",
                        "userId": userId,
                        "userNickname": userNickname,
                        "groupId": toGroupId
                    ]
                )
            }
    }
    
    /// 🎯 미션 할당 시 관련 멤버들에게 알림 전송
    func sendMissionAssignmentNotification(
        missionId: String,
        missionTitle: String,
        UserId: String,
        Nickname: String,
        groupId: String
    ) -> Observable<Void> {
        // 1. Firestore에 알림 데이터 저장
        let notice = DataNoticeFirestore(
            noticeId: UUID().uuidString,
            userId: UserId,
            title: "새로운 미션이 할당되었습니다",
            description: "\(Nickname)님에게 '\(missionTitle)' 미션이 할당되었습니다.",
            category: "mission_assigned",
            url: "stamp-it://mission/\(missionId)",
            isRead: false,
            createdAt: Date()
        )
        
        return noticeManager.create(notice: notice)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                
                // 2. FCM 푸시 알림 전송
                return self.notificationRepository.sendDirectFCMNotificationToGroupMembers(
                    groupId: groupId,
                    title: "새로운 미션이 할당되었습니다",
                    body: "\(UserId)님에게 '\(missionTitle)' 미션이 할당되었습니다.",
                    data: [
                        "type": "mission_assigned",
                        "missionId": missionId,
                        "missionTitle": missionTitle,
                        "assignedUserId": UserId,
                        "assignedUserNickname": Nickname,
                        "groupId": groupId
                    ]
                )
            }
    }
}
