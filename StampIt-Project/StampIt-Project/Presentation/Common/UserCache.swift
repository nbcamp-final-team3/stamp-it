//
//  UserCache.swift
//  StampIt-Project
//
//  Created by iOS study on 6/16/25.
//

import Foundation

final class UserCache {
    static let shared = UserCache()
    private init() {}
    
    // 메모리에만 캐시 저장
    private var cachedUser: User?
    private var cacheTimestamp: Date?
    private let cacheValidDuration: TimeInterval = 300 // 5분
    
    func getCurrentUser() -> User? {
        // 캐시 유효성 검사
        if let cachedUser = cachedUser,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheValidDuration {
            return cachedUser
        }
        
        return nil
    }
    
    func setCurrentUser(_ user: User) {
        cachedUser = user
        cacheTimestamp = Date()
    }
    
    func clearCache() {
        cachedUser = nil
        cacheTimestamp = nil
    }
    
    // 캐시 상태 확인용
    func isCacheValid() -> Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheValidDuration
    }
}
