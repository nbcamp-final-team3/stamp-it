//
//  RepositoryError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/8/25.
//  Repository에서 오류가 추가로 발생하는 경우 enum에 더 정의하셔도 됩니다

import Foundation

// MARK: - Repository Error
/// Repository 계층에서 발생하는 에러 정의
enum RepositoryError: Error {
    case authenticationFailed(String)  // 인증 실패
    case userNotFound                  // 사용자 없음
    case dataError(String)             // 데이터 처리 오류
    case networkError(String)          // 네트워크 오류
    case uiError(String)              // UI 관련 오류
    case unknownError                  // 알 수 없는 오류
    
    var localizedDescription: String {
        switch self {
        case .authenticationFailed(let message):
            return "인증 실패: \(message)"
        case .userNotFound:
            return "사용자를 찾을 수 없습니다"
        case .dataError(let message):
            return "데이터 오류: \(message)"
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        case .uiError(let message):
            return "화면 오류: \(message)"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}
