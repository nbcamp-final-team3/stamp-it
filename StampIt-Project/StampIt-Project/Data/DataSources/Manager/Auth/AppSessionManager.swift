//
//  AppSessionManager.swift
//  StampIt-Project
//
//  Created by 이부용 on 10/13/25.
//

import Foundation
import FirebaseAuth

final class AppSessionManager {
    static let shared = AppSessionManager()
    private init() {}

    // 세션 저장
    func saveKakaoSession(userId: String) {
        UserDefaults.standard.set(userId, forKey: "kakaoUserId")
        UserDefaults.standard.set("kakao", forKey: "loginType")
        NotificationCenter.default.post(name: .userSessionChanged, object: nil)
    }

    // 세션 삭제
    func clearKakaoSession() {
        UserDefaults.standard.removeObject(forKey: "kakaoUserId")
        UserDefaults.standard.removeObject(forKey: "loginType")
        NotificationCenter.default.post(name: .userSessionChanged, object: nil)
    }

    // 로그인 세션 확인
    func isLoggedIn() -> Bool {
        let loginType = UserDefaults.standard.string(forKey: "loginType")
        if loginType == "google" || loginType == "apple" {
            return Auth.auth().currentUser != nil
        } else if loginType == "kakao" {
            return UserDefaults.standard.string(forKey: "kakaoUserId") != nil
        } else {
            return false
        }
    }

    // 세션에 따른 로그인 상태 및 유저 반환
    func getCurrentUserId() -> String? {
        let loginType = UserDefaults.standard.string(forKey: "loginType")
        if loginType == "google" || loginType == "apple" {
            return Auth.auth().currentUser?.uid
        } else if loginType == "kakao" {
            return UserDefaults.standard.string(forKey: "kakaoUserId")
        } else {
            return nil
        }
    }
}

// Notification 커스텀 확장
extension Notification.Name {
    static let userSessionChanged = Notification.Name("userSessionChanged")
}
