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
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "데이터 조회에 실패했습니다. \(message)"
        case .createFailed(let message):
            return "데이터 생성에 실패했습니다. \(message)"
        case .updateFailed(let message):
            return "데이터 업데이트에 실패했습니다. \(message)"
        case .deleteFailed(let message):
            return "데이터 삭제에 실패했습니다. \(message)"
        case .documentNotFound:
            return "문서를 찾을 수 없습니다"
        case .encodingFailed(let message):
            return "데이터 인코딩을 실패했습니다. \(message)"
        case .decodingFailed(let message):
            return "데이터 디코딩을 실패했습니다. \(message)"
        case .networkError(let message):
            return "네트워크 오류가 발생했습니다. \(message)"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

