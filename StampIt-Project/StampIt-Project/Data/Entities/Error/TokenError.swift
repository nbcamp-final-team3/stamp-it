//
//  TokenError.swift
//  StampIt-Project
//
//  Created by 윤주형 on 8/23/25.
//

import Foundation

enum TokenError: LocalizedError {
    case fetchFailed(String)
    case createFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case encodingFailed(String)
    case decodingFailed(String)
    case tokenNotFound
    case invalidToken
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "토큰 조회 실패: \(message)"
        case .createFailed(let message):
            return "토큰 생성 실패: \(message)"
        case .updateFailed(let message):
            return "토큰 업데이트 실패: \(message)"
        case .deleteFailed(let message):
            return "토큰 삭제 실패: \(message)"
        case .encodingFailed(let message):
            return "토큰 인코딩 실패: \(message)"
        case .decodingFailed(let message):
            return "토큰 디코딩 실패: \(message)"
        case .tokenNotFound:
            return "토큰을 찾을 수 없습니다"
        case .invalidToken:
            return "유효하지 않은 토큰입니다"
        }
    }
}
