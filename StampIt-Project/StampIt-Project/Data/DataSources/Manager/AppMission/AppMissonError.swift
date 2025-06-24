//
//  AppMissionError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation

enum AppMissionError: Error, LocalizedError {
    // 앱 미션 관련 특화 에러
    case appMissionNotFound
    case invalidCategory
    case duplicateAppMission
    case appMissionUnavailable
    
    // 일반적인 AppMission 작업 에러
    case createFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case encodingFailed(String)
    case decodingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .appMissionNotFound:
            return "앱 미션을 찾을 수 없습니다"
        case .invalidCategory:
            return "유효하지 않은 카테고리입니다"
        case .duplicateAppMission:
            return "중복된 앱 미션입니다"
        case .appMissionUnavailable:
            return "현재 사용할 수 없는 앱 미션입니다"
        case .createFailed(let message):
            return "앱 미션 생성에 실패했습니다: \(message)"
        case .fetchFailed(let message):
            return "앱 미션 정보 조회에 실패했습니다: \(message)"
        case .updateFailed(let message):
            return "앱 미션 정보 업데이트에 실패했습니다: \(message)"
        case .deleteFailed(let message):
            return "앱 미션 삭제에 실패했습니다: \(message)"
        case .encodingFailed(let message):
            return "앱 미션 데이터 인코딩에 실패했습니다: \(message)"
        case .decodingFailed(let message):
            return "앱 미션 데이터 디코딩에 실패했습니다: \(message)"
        }
    }
}
