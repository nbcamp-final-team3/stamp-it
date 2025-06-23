//
//  AuthError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/10/25.
//

import Foundation

enum AuthError: Error, LocalizedError {
    case presentingViewControllerNotFound
    case googleSignInFailed
    case tokenRetrievalFailed
    case firebaseSignInFailed
    case appleSignInCanceled
    case appleSignInNotImplemented
    case appleSignInFailed
    case signOutFailed
    case accountDeletionFailed
    case userNotFound
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .presentingViewControllerNotFound:
            return "화면을 찾을 수 없습니다."
        case .googleSignInFailed:
            return ""
        case .tokenRetrievalFailed:
            return "토큰을 가져올 수 없습니다."
        case .firebaseSignInFailed:
            return "Firebase 로그인 실패에 실패했습니다."
        case .appleSignInCanceled:
            return ""
        case .appleSignInNotImplemented:
            return "" // TODO: 리팩토링때 삭제, 애플 로그인 구현 전 에러
        case .signOutFailed:
            return "로그아웃에 실패했습니다."
        case .accountDeletionFailed:
            return "계정 삭제에 실패했습니다."
        case .userNotFound:
            return "사용자를 찾을 수 없습니다."
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        case .appleSignInFailed:
            return "애플 인증 정보가 올바르지 않습니다."
        }
    }
}
