//
//  GroupExitError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/18/25.
//

import Foundation

// MARK: - 그룹 탈퇴 전용 에러 타입
enum GroupExitError: Error, LocalizedError {
    case userNotFound
    case groupNotFound
    case batchCommitFailed(String)
    case dataCleanupFailed(String)
    case rollbackFailed(String)
    case networkTimeout
    case insufficientPermissions
    case transactionConflict
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "사용자 정보를 찾을 수 없습니다"
        case .groupNotFound:
            return "그룹 정보를 찾을 수 없습니다"
        case .batchCommitFailed(let message):
            return "그룹 탈퇴 처리 실패: \(message)"
        case .dataCleanupFailed(let message):
            return "이전 데이터 정리 실패: \(message)"
        case .rollbackFailed(let message):
            return "롤백 처리 실패: \(message)"
        case .networkTimeout:
            return "네트워크 연결 시간 초과"
        case .insufficientPermissions:
            return "작업 권한이 부족합니다"
        case .transactionConflict:
            return "동시 작업 충돌이 발생했습니다"
        }
    }
}
