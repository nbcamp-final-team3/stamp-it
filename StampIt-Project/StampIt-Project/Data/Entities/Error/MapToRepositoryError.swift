//
//  MapToRepositoryError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/24/25.
//

// MARK: - Error 처리
/// 다양한 에러 타입을 RepositoryError로 매핑 (새로운 에러 타입 반영)
func mapToRepositoryError(_ error: Error) -> RepositoryError {
    // User 에러 처리
    if let userError = error as? UserError {
        switch userError {
        case .userNotFound:
            return .userNotFound
        case .fetchFailed(let message):
            return .dataError("사용자 조회 실패: \(message)")
        case .createFailed(let message):
            return .dataError("사용자 생성 실패: \(message)")
        case .updateFailed(let message):
            return .dataError("사용자 업데이트 실패: \(message)")
        default:
            return .dataError("사용자 오류: \(userError.localizedDescription)")
        }
    }
    
    // Group 에러 처리
    if let groupError = error as? GroupError {
        switch groupError {
        case .groupNotFound:
            return .userNotInGroup
        case .fetchFailed(let message):
            return .dataError("그룹 조회 실패: \(message)")
        case .createFailed(let message):
            return .dataError("그룹 생성 실패: \(message)")
        default:
            return .dataError("그룹 오류: \(groupError.localizedDescription)")
        }
    }
    
    // Membership 에러 처리
    if let membershipError = error as? MembershipError {
        switch membershipError {
        case .memberNotFound:
            return .userNotInGroup
        case .fetchFailed(let message):
            return .dataError("멤버십 조회 실패: \(message)")
        default:
            return .dataError("멤버십 오류: \(membershipError.localizedDescription)")
        }
    }
    
    // Firebase Auth 에러 처리
    if let authError = error as? AuthError {
        switch authError {
        case .googleSignInFailed:
            return .authenticationFailed("Google 로그인 실패")
        case .firebaseSignInFailed:
            return .authenticationFailed("Firebase 로그인 실패")
        case .userNotFound:
            return .userNotFound
        case .presentingViewControllerNotFound:
            return .uiError("화면을 찾을 수 없습니다")
        case .signOutFailed:
            return .authenticationFailed("로그아웃 실패")
        case .accountDeletionFailed:
            return .authenticationFailed("계정 삭제 실패")
        default:
            return .authenticationFailed(authError.localizedDescription)
        }
    }
    
    // 네트워크 에러 처리
    if let nsError = error as NSError? {
        switch nsError.code {
        case NSURLErrorTimedOut:
            return .networkError("연결 시간 초과")
        case NSURLErrorNotConnectedToInternet:
            return .networkError("인터넷 연결이 없습니다")
        case NSURLErrorNetworkConnectionLost:
            return .networkError("네트워크 연결이 끊어졌습니다")
        default:
            break
        }
    }
    
    return .unknownError
}
