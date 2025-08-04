//
//  FCMError.swift
//  StampIt-Project
//
//  Created by 윤주형 on 7/29/25.
//

import Foundation

enum FCMError: Error, LocalizedError {
    case tokenRetrievalFailed
    case tokenUpdateFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .tokenRetrievalFailed:
            return "FCM 토큰을 가져올 수 없습니다."
        case .tokenUpdateFailed:
            return "FCM 토큰 업데이트에 실패했습니다."
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}
