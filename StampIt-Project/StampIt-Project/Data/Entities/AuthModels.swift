//
//  AuthModels.swift
//  StampIt-Project
//
//  Created by iOS study on 6/8/25.
//

// MARK: - Models (DTO-전달용)
// 인증+DB처리 결과 한 번에 전달
struct AuthResult {
    let user: User                    // 도메인 모델 (앱에서 사용)
    let userFirestore: UserFirestore  // Firestore 저장 모델
    let isNewUser: Bool               // 신규 가입 여부
    let providerId: String            // 로그인 제공자 (google.com, apple.com)
}

// 간단한 유저 정보만 추출 (사용자 기본 정보 모델)
struct UserInfo {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: String?
    let providerId: String?
}
