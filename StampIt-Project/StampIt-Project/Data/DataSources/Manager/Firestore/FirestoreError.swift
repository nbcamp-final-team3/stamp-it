//
//  FirestoreError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/8/25.
//

import Foundation

// MARK: - Network Error Handling
enum FirestoreError: Error, LocalizedError {
    case networkUnavailable(String)
    case connectionTimeout(String)
    case serverUnavailable(String)
    case permissionDenied(String)
    case unauthenticated(String)
    case documentNotFound
    case unknownNetworkError
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable(let message):
            return "네트워크 연결을 확인해주세요. \(message)"
        case .connectionTimeout(let message):
            return "연결 시간이 초과되었습니다. \(message)"
        case .serverUnavailable(let message):
            return "서버에 일시적으로 연결할 수 없습니다. \(message)"
        case .permissionDenied(let message):
            return "접근 권한이 없습니다. \(message)"
        case .unauthenticated(let message):
            return "인증이 필요합니다. \(message)"
        case .documentNotFound:
            return "요청한 데이터를 찾을 수 없습니다"
        case .unknownNetworkError:
            return "알 수 없는 네트워크 오류가 발생했습니다"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .connectionTimeout, .serverUnavailable:
            return true
        case .permissionDenied, .unauthenticated, .documentNotFound, .unknownNetworkError:
            return false
        }
    }
}
