//
//  UserError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation

enum UserError: Error, LocalizedError {
    // 사용자 관련 특화 에러
    case userNotFound
    case userAlreadyExists
    case invalidInput(String)

    // 일반적인 User 작업 에러
    case createFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case encodingFailed(String)
    case decodingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "사용자를 찾을 수 없습니다"
        case .userAlreadyExists:
            return "이미 존재하는 사용자입니다"
        case .createFailed(let message):
            return "사용자 생성에 실패했습니다: \(message)"
        case .fetchFailed(let message):
            return "사용자 정보 조회에 실패했습니다: \(message)"
        case .updateFailed(let message):
            return "사용자 정보 업데이트에 실패했습니다: \(message)"
        case .deleteFailed(let message):
            return "사용자 삭제에 실패했습니다: \(message)"
        case .encodingFailed(let message):
            return "사용자 데이터 인코딩에 실패했습니다: \(message)"
        case .decodingFailed(let message):
            return "사용자 데이터 디코딩에 실패했습니다: \(message)"
        case .invalidInput(let message):
            return "잘못된 입력: \(message)"
        }
    }
}
