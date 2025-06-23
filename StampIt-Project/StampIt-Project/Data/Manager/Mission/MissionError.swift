//
//  MissionError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation

enum MissionError: Error, LocalizedError {
    // 미션 관련 특화 에러
    case missionNotFound
    case missionAlreadyCompleted
    case missionExpired
    case invalidAssignment
    case duplicateMission
    
    // 일반적인 Mission 작업 에러
    case createFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case encodingFailed(String)
    case decodingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missionNotFound:
            return "미션을 찾을 수 없습니다"
        case .missionAlreadyCompleted:
            return "이미 완료된 미션입니다"
        case .missionExpired:
            return "만료된 미션입니다"
        case .invalidAssignment:
            return "유효하지 않은 미션 할당입니다"
        case .duplicateMission:
            return "중복된 미션입니다"
        case .createFailed(let message):
            return "미션 생성에 실패했습니다: \(message)"
        case .fetchFailed(let message):
            return "미션 정보 조회에 실패했습니다: \(message)"
        case .updateFailed(let message):
            return "미션 정보 업데이트에 실패했습니다: \(message)"
        case .deleteFailed(let message):
            return "미션 삭제에 실패했습니다: \(message)"
        case .encodingFailed(let message):
            return "미션 데이터 인코딩에 실패했습니다: \(message)"
        case .decodingFailed(let message):
            return "미션 데이터 디코딩에 실패했습니다: \(message)"
        }
    }
}
