//
//  UserQuery.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation

struct UserQuery {
    let userIds: [String]?
    let nicknameContains: String?
    let createdAfter: Date?
    let orderBy: OrderBy?
    let limit: Int?
    
    struct OrderBy {
        let field: String
        let descending: Bool
    }
    
    // MARK: - 편의 생성자들
    
    /// 특정 사용자들 조회
    static func users(ids: [String]) -> UserQuery {
        return UserQuery(
            userIds: ids,
            nicknameContains: nil,
            createdAfter: nil,
            orderBy: OrderBy(field: "nickname", descending: false),
            limit: nil
        )
    }
    
    /// 닉네임 검색
    static func searchByNickname(_ nickname: String, limit: Int = 20) -> UserQuery {
        return UserQuery(
            userIds: nil,
            nicknameContains: nickname,
            createdAfter: nil,
            orderBy: OrderBy(field: "nickname", descending: false),
            limit: limit
        )
    }
    
    // TODO:  최근 가입자 조회 (관리용으로 리팩토링 후 확인 후 삭제 예정)
    static func recentUsers(limit: Int = 10) -> UserQuery {
        return UserQuery(
            userIds: nil,
            nicknameContains: nil,
            createdAfter: nil,
            orderBy: OrderBy(field: "createdAt", descending: true),
            limit: limit
        )
    }
}
