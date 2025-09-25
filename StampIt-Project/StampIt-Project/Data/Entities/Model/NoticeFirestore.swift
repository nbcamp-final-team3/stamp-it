//
//  NoticeFirestore.swift
//  StampIt-Project
//
//  Created by 윤주형 on 7/8/25.
//

import Foundation
import FirebaseCore

// TODO: category와 url의 path가 중복되어 개별 필드로 가지고 있을 필요성에 대해 재고 필요
struct NoticeFirestore: Codable {
    let noticeId: String
    let title: String
    let description: String
    let category: String
    let createdAt: Timestamp
    let url: String
    let isRead: Bool
    let userId: String
}

extension NoticeFirestore {
    func toDomain() -> Notice {
        return Notice(
            noticeId: noticeId,
            title: title,
            description: description,
            category: NoticeCategory(rawValue: category) ?? .unknown,
            createdAt: createdAt.dateValue(),
            isRead: isRead
        )
    }
}
