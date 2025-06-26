//
//  GroupUseCaseError.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/26/25.
//

import Foundation

// MARK: - Group UseCase Error
/// 그룹 관리 UseCase에서 발생하는 에러 정의
enum GroupUseCaseError: Error {
    case notAuthorized                  // 권한 없음 (리더가 아님)
    
    // Repository 에러들
    case authenticationFailed(String)   // 인증 실패
    case userNotFound                   // 사용자 없음
    case userNotInGroup                 // 그룹 정보 없음
    case dataProcessingFailed(String)   // 데이터 처리 실패
    case networkFailed(String)          // 네트워크 실패
    case uiFailed(String)               // UI 관련 실패
    case groupIsFull                    // 그룹 정원이 가득 찬 오류
    case onlyOneGroup                   // 유저는 그룹을 하나만 가질 수 있음
    case noInviteCode                   // 초대 코드가 없는 오류
    case expiredInviteCode              // 초대 만료 오류
    case alreadyInGroup                 // 이미 그룹에 있는 경우
    case unknownError                   // 알 수 없는 오류
    
    var localizedDescription: String {
        switch self {
        case .notAuthorized:
            return "리더만 사용할 수 있는 기능입니다."
        case .authenticationFailed(let message):
            return "인증 실패: \(message)"
        case .userNotFound:
            return "사용자 정보를 찾을 수 없습니다"
        case .userNotInGroup:
            return "그룹 정보를 찾을 수 없습니다"
        case .dataProcessingFailed(let message):
            return "데이터 처리 실패: \(message)"
        case .networkFailed(let message):
            return "네트워크 실패: \(message)"
        case .uiFailed(let message):
            return "화면 오류: \(message)"
        case .groupIsFull:
            return "그룹 정원이 가득 찼습니다."
        case .onlyOneGroup:
            return "유저는 그룹을 하나만 가질 수 있음"
        case .noInviteCode:
            return "초대 코드가 없는 오류"
        case .expiredInviteCode:
            return "초대 만료 오류"
        case .alreadyInGroup:
            return "이미 그룹에 있는 경우"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
    
    /// UI에서 사용자에게 표시할 친화적 메시지
    var userFriendlyMessage: String {
        switch self {
        case .notAuthorized:
            return "리더만 사용할 수 있는 기능입니다."
        case .authenticationFailed(_):
            return "로그인에 실패했습니다. 다시 시도해주세요."
        case .userNotFound:
            return "사용자 정보를 불러올 수 없습니다."
        case .userNotInGroup:
            return "그룹 정보를 찾을 수 없습니다."
        case .dataProcessingFailed(_):
            return "데이터 처리 중 오류가 발생했습니다."
        case .networkFailed(_):
            return "네트워크 연결을 확인해주세요."
        case .uiFailed(_):
            return "화면 표시 중 오류가 발생했습니다."
        case .groupIsFull:
            return "그룹 정원이 가득 찼습니다."
        case .onlyOneGroup:
            return "기존 그룹을 탈퇴해 주세요."
        case .noInviteCode:
            return "초대 코드를 확인 할 수 없습니다."
        case .expiredInviteCode:
            return "초대 코드가 만료됐습니다."
        case .alreadyInGroup:
            return "이미 그룹에 존재합니다."
        case .unknownError:
            return "예상치 못한 오류가 발생했습니다."
        }
    }
    
    /// 토스트 메시지용 텍스트
    var toastMessage: String {
        switch self {
        case .notAuthorized:
            return "리더만 사용할 수 있는 기능입니다."
        case .authenticationFailed(_):
            return "로그인에 실패했습니다."
        case .userNotFound:
            return "사용자 정보를 불러올 수 없습니다."
        case .userNotInGroup:
            return "그룹 정보를 찾을 수 없습니다."
        case .dataProcessingFailed(_):
            return "데이터 처리 중 오류가 발생했습니다."
        case .networkFailed(_):
            return "네트워크 연결을 확인해주세요."
        case .uiFailed(_):
            return "화면 표시 중 오류가 발생했습니다."
        case .groupIsFull:
            return "그룹 정원이 가득 찼습니다."
        case .onlyOneGroup:
            return "기존 그룹을 탈퇴해 주세요."
        case .noInviteCode:
            return "초대 코드를 확인 할 수 없습니다."
        case .expiredInviteCode:
            return "초대 코드가 만료됐습니다."
        case .alreadyInGroup:
            return "이미 그룹에 존재합니다."
        case .unknownError:
            return "예상치 못한 오류가 발생했습니다."
        }
    }
    
    /// RepositoryError를 GroupUseCaseError로 변환
    static func fromRepositoryError(_ error: RepositoryError) -> GroupUseCaseError {
        switch error {
        case .authenticationFailed(let message):
            return .authenticationFailed(message)
        case .userNotFound:
            return .userNotFound
        case .userNotInGroup:
            return .userNotInGroup
        case .dataError(let message):
            return .dataProcessingFailed(message)
        case .networkError(let message):
            return .networkFailed(message)
        case .uiError(let message):
            return .uiFailed(message)
        case .permissionDenied(let message):
            return .authenticationFailed(message)
        case .unknownError:
            return .unknownError
        case .groupIsFull:
            return .groupIsFull
        case .onlyOneGroup:
            return .onlyOneGroup
        case .noInviteCode:
            return .noInviteCode
        case .expiredInviteCode:
            return .expiredInviteCode
        case .alreadyInGroup:
            return .alreadyInGroup
        }
    }
    
    /// Manager 에러들을 GroupUseCaseError로 변환
    static func fromManagerError(_ error: Error) -> GroupUseCaseError {
        // UserError 처리
        if let userError = error as? UserError {
            switch userError {
            case .userNotFound:
                return .userNotFound
            case .fetchFailed(let message):
                return .dataProcessingFailed("사용자 조회 실패: \(message)")
            case .createFailed(let message):
                return .dataProcessingFailed("사용자 생성 실패: \(message)")
            case .updateFailed(let message):
                return .dataProcessingFailed("사용자 업데이트 실패: \(message)")
            default:
                return .dataProcessingFailed("사용자 오류: \(userError.localizedDescription)")
            }
        }
        
        // GroupError 처리
        if let groupError = error as? GroupError {
            switch groupError {
            case .groupNotFound:
                return .userNotInGroup
            case .fetchFailed(let message):
                return .dataProcessingFailed("그룹 조회 실패: \(message)")
            case .createFailed(let message):
                return .dataProcessingFailed("그룹 생성 실패: \(message)")
            case .updateFailed(let message):
                return .dataProcessingFailed("그룹 업데이트 실패: \(message)")
            default:
                return .dataProcessingFailed("그룹 오류: \(groupError.localizedDescription)")
            }
        }
        
        // MembershipError 처리
        if let membershipError = error as? MembershipError {
            switch membershipError {
            case .memberNotFound:
                return .userNotFound
            case .fetchFailed(let message):
                return .dataProcessingFailed("멤버십 조회 실패: \(message)")
            case .createFailed(let message):
                return .dataProcessingFailed("멤버십 생성 실패: \(message)")
            case .updateFailed(let message):
                return .dataProcessingFailed("멤버십 업데이트 실패: \(message)")
            default:
                return .dataProcessingFailed("멤버십 오류: \(membershipError.localizedDescription)")
            }
        }
        
        return .unknownError
    }
} 