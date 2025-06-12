//
//  AuthError.swift
//  StampIt-Project
//
//  Created by iOS study on 6/10/25.
//

import Foundation

enum AuthError: Error, LocalizedError {
    case presentingViewControllerNotFound
    case googleSignInFailed(String)
    case tokenRetrievalFailed
    case firebaseSignInFailed(String)
    case appleSignInNotImplemented
    case signOutFailed(String)
    case accountDeletionFailed(String)
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .presentingViewControllerNotFound:
            return "화면을 찾을 수 없습니다."
        case .googleSignInFailed(let message):
            return "Google 로그인 실패: \(message)"
        case .tokenRetrievalFailed:
            return "토큰을 가져올 수 없습니다."
        case .firebaseSignInFailed(let message):
            return "Firebase 로그인 실패: \(message)"
        case .appleSignInNotImplemented:
            return "Apple 로그인은 아직 구현되지 않았습니다."
        case .signOutFailed(let message):
            return "로그아웃 실패: \(message)"
        case .accountDeletionFailed(let message):
            return "계정 삭제 실패: \(message)"
        case .userNotFound:
            return "사용자를 찾을 수 없습니다."
        }
    }
}
