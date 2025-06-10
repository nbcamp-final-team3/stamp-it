//
//  FirestoreError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/8/25.
//

import Foundation

// MARK: - Error Handling
enum FirestoreError: Error, LocalizedError {
    case fetchFailed(String)
    case createFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case documentNotFound
    case encodingFailed(String)
    case decodingFailed(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "데이터 조회 실패: \(message)"
        case .createFailed(let message):
            return "데이터 생성 실패: \(message)"
        case .updateFailed(let message):
            return "데이터 업데이트 실패: \(message)"
        case .deleteFailed(let message):
            return "데이터 삭제 실패: \(message)"
        case .documentNotFound:
            return "문서를 찾을 수 없습니다"
        case .encodingFailed(let message):
            return "데이터 인코딩 실패: \(message)"
        case .decodingFailed(let message):
            return "데이터 디코딩 실패: \(message)"
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        }
    }
}

