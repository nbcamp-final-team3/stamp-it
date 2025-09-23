//
//  NoticeRepositoryImpl.swift
//  StampIt-Project
//
//  Created by daeun on 8/4/25.
//

import Foundation
import RxSwift
import FirebaseFirestore // FIXME: Manager에서 Date -> TimeStamp 변환하도록 변경하여 의존도 낮추기

final class NoticeRepository: NoticeRepositoryProtocol {
    private let noticeManager: any NoticeManagerProtocol
    private let authManager: any AuthManagerProtocol

    init(noticeManager: any NoticeManagerProtocol, authManager: any AuthManagerProtocol) {
        self.noticeManager = noticeManager
        self.authManager = authManager
    }

    func createNotice(_ notice: Notice, receiverId: String) -> Observable<Void> {
        let noticeFireStore = NoticeFirestore(
            noticeId: notice.noticeId,
            title: notice.title,
            description: notice.description,
            category: notice.category.rawValue,
            createdAt: Timestamp(date: notice.createdAt),
            url: "stampit://\(notice.category.rawValue)",
            isRead: notice.isRead,
            userId: receiverId
        )
        return noticeManager.create(notice: noticeFireStore)
    }

    func fetchNotices() -> Observable<[Notice]> {
        guard let currentUserId = authManager.getCurrentUser()?.uid else {
            return .error(AuthError.userNotFound)
        }

        let query = NoticeQuery.builder()
            .userId(currentUserId)
            .orderBy(.createdAtDesc)
            .build()

        return noticeManager.observeNotices(query: query)
            .map { $0.map { $0.toDomain() } }
    }

    func readNotice(_ noticeId: String) -> Observable<Void> {
        noticeManager.markAsRead(id: noticeId)
    }
}
