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
    private let fcmManager: FCMManagerProtocol
    private var tokenObserver: NSObjectProtocol?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentUserId: String?
    
    init(fcmManager: FCMManagerProtocol) {
        self.fcmManager = fcmManager
//        setupTokenObserver()
        setupAuthStateObserver()
    }
    
    deinit {
        // 리스너들 정리
        if let tokenObserver { NotificationCenter.default.removeObserver(tokenObserver) }
        if let authStateListener { Auth.auth().removeStateDidChangeListener(authStateListener) }
    }
    
//    // MARK: - 토큰 갱신 이벤트 구독
//    private func setupTokenObserver() {
//        tokenObserver = NotificationCenter.default.addObserver(
//            forName: .fcmTokenDidRefresh,
//            object: nil,
//            queue: .main
//        ) { [weak self] notification in
//            guard
//                let self = self,
//                let uid = self.currentUserId,  // 로그인 되어 있어야 서버에 씀
//                let token = notification.userInfo?["token"] as? String
//            else { return }
//            
//            print("🔄 TokenCoordinator: 토큰 갱신 이벤트 수신 - 사용자: \(uid)")
//            self.fcmManager.upsertToken(token, for: uid)
//        }
//    }
    
    // MARK: - 인증 상태 변화 감지
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
