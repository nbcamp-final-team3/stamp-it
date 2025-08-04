//
//  NoticeRepositoryImpl.swift
//  StampIt-Project
//
//  Created by daeun on 8/4/25.
//

import Foundation
import RxSwift

final class NoticeRepository: NoticeRepositoryProtocol {
    private let noticeManager: NoticeManager
    private let authManager: AuthManager

    init(noticeManager: NoticeManager, authManager: AuthManager) {
        self.noticeManager = noticeManager
        self.authManager = authManager
    }

    func fetchNotices() -> Observable<[Notice]> {
        guard let currentUserId = authManager.getCurrentUser()?.uid else {
            return .error(AuthError.userNotFound)
        }

        let query = NoticeQuery.builder()
            .userId(currentUserId)
            .build()

        return noticeManager.observeNotices(query: query)
            .map { $0.map { $0.toDomain() } }
    }

    func readNotice(_ noticeId: String) -> Observable<Void> {
        noticeManager.markAsRead(id: noticeId)
    }
}
