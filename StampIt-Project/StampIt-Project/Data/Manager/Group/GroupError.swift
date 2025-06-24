//
//  GroupError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation

// MARK: - GroupError 정의 (완전 수정)
enum GroupError: Error, LocalizedError {
    case groupNotFound
    case groupAlreadyExists
    case inviteNotFound
    case inviteExpired
    case invalidInput(String)
    
    // 일반적인 Group 작업 에러
    case createFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case encodingFailed(String)
    case decodingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .groupNotFound:
            return "그룹을 찾을 수 없습니다"
        case .groupAlreadyExists:
            return "이미 존재하는 그룹입니다"
        case .inviteNotFound:
            return "초대 코드를 찾을 수 없습니다"
        case .inviteExpired:
            return "만료된 초대 코드입니다"
        case .invalidInput(let message):
            return "잘못된 입력: \(message)"
        case .createFailed(let message):
            return "그룹 생성에 실패했습니다: \(message)"
        case .fetchFailed(let message):
            return "그룹 정보 조회에 실패했습니다: \(message)"
        case .updateFailed(let message):
            return "그룹 정보 업데이트에 실패했습니다: \(message)"
        case .deleteFailed(let message):
            return "그룹 삭제에 실패했습니다: \(message)"
        case .encodingFailed(let message):
            return "그룹 데이터 인코딩에 실패했습니다: \(message)"
        case .decodingFailed(let message):
            return "그룹 데이터 디코딩에 실패했습니다: \(message)"
        }
    }
}
