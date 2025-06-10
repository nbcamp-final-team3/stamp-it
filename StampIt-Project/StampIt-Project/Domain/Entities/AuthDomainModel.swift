//
//  AuthDomainModel.swift
//  StampIt-Project
//
//  Created by iOS study on 6/8/25.
//

// MARK: - Repository 전용 Models

struct AuthUser {
    let uid: String
    let email: String
    let displayName: String
    let photoURL: String?
    let isNewUser: Bool
}

/// 로그인 완료 결과
struct LoginResult {
    let user: User              // 도메인 모델
    let isNewUser: Bool         // 신규 가입 여부
    let needsGroupSetup: Bool   // 그룹 설정 필요 여부
}

/// 런치 화면 결과
struct LaunchResult {
    let isAuthenticated: Bool   // 인증 상태
    let user: User?            // 사용자 정보 (인증된 경우)
    let needsOnboarding: Bool  // 온보딩 필요 여부
}

// MARK: - UseCase 전용 Models
/// 로그인 플로우 결과
struct LoginFlowResult {
    let user: User
    let isNewUser: Bool
    let nextAction: LoginNextAction
}

/// 로그인 후 다음 액션
enum LoginNextAction {
    case navigateToMain          // 메인 화면으로 이동
    case showWelcomeMessage      // 환영 메시지 표시 후 메인
    case setupGroup             // 그룹 설정 필요
}

/// 런치 플로우 결과 (화면 분기용)
struct LaunchFlowResult {
    let nextScreen: LaunchNextScreen
    let user: User?
}

/// 런치 후 이동할 화면
enum LaunchNextScreen {
    case login                  // 로그인 화면
    case onboarding            // 온보딩 화면
    case main                  // 메인 화면
    case groupSetup            // 그룹 설정 화면
}
