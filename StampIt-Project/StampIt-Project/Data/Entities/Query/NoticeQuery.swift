//
//  NoticeQuery.swift
//  StampIt-Project
//
//  Created by iOS study on 7/11/25.
//

import Foundation

struct NoticeQuery {
    var userId: String?
    var isRead: Bool?
    var limit: Int?
    var orderBy: OrderBy?
    
    enum OrderBy {
        case createdAtDesc
        case createdAtAsc
    }
}

// 쿼리 빌더 패턴
extension NoticeQuery {
    static func builder() -> NoticeQueryBuilder {
        return NoticeQueryBuilder()
    }
}

class NoticeQueryBuilder {
    private var query = NoticeQuery()
    
    func userId(_ userId: String) -> NoticeQueryBuilder {
        query.userId = userId
        return self
    }
    
    func isRead(_ isRead: Bool) -> NoticeQueryBuilder {
        query.isRead = isRead
        return self
    }
    
    func limit(_ limit: Int) -> NoticeQueryBuilder {
        query.limit = limit
        return self
    }
    
    func orderBy(_ orderBy: NoticeQuery.OrderBy) -> NoticeQueryBuilder {
        query.orderBy = orderBy
        return self
    }
    
    func build() -> NoticeQuery {
        return query
    }
}
