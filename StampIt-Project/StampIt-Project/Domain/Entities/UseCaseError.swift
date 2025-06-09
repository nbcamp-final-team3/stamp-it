//
//  UseCaseError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/8/25.
//

import Foundation

// MARK: - UseCase Error
/// UseCase 계층에서 발생하는 에러 정의
enum UseCaseError: Error {
    case authenticationFailed(String)   // 인증 실패
    case userNotFound                   // 사용자 없음
    case validationFailed(String)       // 유효성 검증 실패
    case processingFailed(String)       // 처리 실패
    case dataProcessingFailed(String)   // 데이터 처리 실패
    case networkFailed(String)          // 네트워크 실패
    case uiFailed(String)               // UI 관련 실패
    case timeoutError                   // 타임아웃
    case unknownError                   // 알 수 없는 오류
    
    var localizedDescription: String {
        switch self {
        case .authenticationFailed(let message):
            return "로그인 실패: \(message)"
        case .userNotFound:
            return "사용자 정보를 찾을 수 없습니다"
        case .validationFailed(let message):
            return "검증 실패: \(message)"
        case .processingFailed(let message):
            return "처리 실패: \(message)"
        case .dataProcessingFailed(let message):
            return "데이터 처리 실패: \(message)"
        case .networkFailed(let message):
            return "네트워크 오류: \(message)"
        case .uiFailed(let message):
            return "화면 오류: \(message)"
        case .timeoutError:
            return "요청 시간이 초과되었습니다"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
    
    /// UI에서 사용자에게 표시할 친화적 메시지
    var userFriendlyMessage: String {
        switch self {
        case .authenticationFailed(_):
            return "로그인에 실패했습니다. 다시 시도해주세요."
        case .userNotFound:
            return "사용자 정보를 불러올 수 없습니다."
        case .validationFailed(_):
            return "입력 정보를 확인해주세요."
        case .processingFailed(_):
            return "처리 중 오류가 발생했습니다."
        case .dataProcessingFailed(_):
            return "데이터 처리 중 오류가 발생했습니다."
        case .networkFailed(_):
            return "네트워크 연결을 확인해주세요."
        case .uiFailed(_):
            return "화면 표시 중 오류가 발생했습니다."
        case .timeoutError:
            return "요청 시간이 초과되었습니다. 다시 시도해주세요."
        case .unknownError:
            return "예상치 못한 오류가 발생했습니다."
        }
    }
}
