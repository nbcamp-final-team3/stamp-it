//
//  StampError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation

// MARK: - StampError 정의 (완전 수정)
enum StampError: Error, LocalizedError {
    case stampNotFound
    case stampAlreadyExists
    case invalidInput(String)
    
    // 일반적인 Stamp 작업 에러
    case createFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case encodingFailed(String)
    case decodingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .stampNotFound:
            return "스티커를 찾을 수 없습니다"
        case .stampAlreadyExists:
            return "이미 존재하는 스티커입니다"
        case .invalidInput(let message):
            return "잘못된 입력: \(message)"
        case .createFailed(let message):
            return "스티커 생성에 실패했습니다: \(message)"
        case .fetchFailed(let message):
            return "스티커 정보 조회에 실패했습니다: \(message)"
        case .updateFailed(let message):
            return "스티커 정보 업데이트에 실패했습니다: \(message)"
        case .deleteFailed(let message):
            return "스티커 삭제에 실패했습니다: \(message)"
        case .encodingFailed(let message):
            return "스티커 데이터 인코딩에 실패했습니다: \(message)"
        case .decodingFailed(let message):
            return "스티커 데이터 디코딩에 실패했습니다: \(message)"
        }
    }
}
