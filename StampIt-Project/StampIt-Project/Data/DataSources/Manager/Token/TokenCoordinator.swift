//
//  TokenCoordinator.swift
//  StampIt-Project
//
//  Created by 윤주형 on 8/23/25.
//

import Foundation
import FirebaseAuth
import FirebaseMessaging

final class TokenCoordinator {
    private let fcmManager: FCMTokenManagerProtocol
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentUserId: String?
    
    init(fcmManager: FCMTokenManagerProtocol) {
        self.fcmManager = fcmManager
        setupAuthStateObserver()
    }
    
    deinit {
        // 리스너들 정리
        if let authStateListener { Auth.auth().removeStateDidChangeListener(authStateListener) }
    }
    
    // MARK: - 인증 상태 변화 감지 test완료
    private func setupAuthStateObserver() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.currentUserId = user.uid
                print("✅ TokenCoordinator: 사용자 로그인 감지 - UID: \(user.uid)")
                
                // 로그인 직후 토큰 저장 시도 (한 번만)
                if let cachedToken = UserDefaults.standard.string(forKey: "FCMToken") {
                    print("🔄 TokenCoordinator: 캐시된 토큰으로 초기 저장")
                    self?.fcmManager.upsertToken(cachedToken, for: user.uid)
                } else {
                    // 캐시된 토큰이 없을 때만 Messaging.messaging().token으로 확인
                    Messaging.messaging().token { token, error in
                        if let token = token, error == nil {
                            print("🔄 TokenCoordinator: Messaging.messaging().token으로 토큰 확인 후 저장")
                            self?.fcmManager.upsertToken(token, for: user.uid)
                        }
                    }
                }
            } else {
                self?.currentUserId = nil
                print("❌ TokenCoordinator: 사용자 로그아웃 감지")
            }
        }
    }
}
