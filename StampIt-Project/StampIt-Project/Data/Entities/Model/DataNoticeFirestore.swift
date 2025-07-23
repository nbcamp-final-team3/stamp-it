//
//  DataNoticeFirestore.swift
//  StampIt-Project
//
//  Created by 윤주형 on 7/8/25.
//

import Foundation
import FirebaseCore

struct DataNoticeFirestore {
    let id: String
    let title: String
    let description: String
    let category: String
    let createdAt: Timestamp
    let url: String
    let isRead: Bool
}

extension DataNoticeFirestore {
    func toDomain() -> Notice {
        return Notice(
            id: id,
            title: title,
            description: description,
            category: NoticeCategory(rawValue: category) ?? .unknown,
            createdAt: createdAt.dateValue(),
            isRead: isRead
        )
    }
}
