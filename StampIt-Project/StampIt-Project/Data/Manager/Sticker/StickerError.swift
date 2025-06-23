//
//  StickerError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation

enum StickerError: Error, LocalizedError {
    // 스티커 관련 특화 에러
    case stickerNotFound
    case stickerAlreadyExists
    case invalidPinNumber
    case stickerLimitExceeded
    case invalidStickerType
    case unknownError
    
    // 일반적인 Sticker 작업 에러
    case createFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case encodingFailed(String)
    case decodingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .stickerNotFound:
            return "스티커를 찾을 수 없습니다"
        case .stickerAlreadyExists:
            return "이미 존재하는 스티커입니다"
        case .invalidPinNumber:
            return "유효하지 않은 핀 번호입니다"
        case .stickerLimitExceeded:
            return "스티커 개수 제한을 초과했습니다"
        case .invalidStickerType:
            return "유효하지 않은 스티커 타입입니다"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다"
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
