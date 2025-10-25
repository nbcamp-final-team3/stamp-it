//
//  KakaoAuthManager.swift
//  StampIt-Project
//
//  Created by 이부용 on 9/30/25.
//

import KakaoSDKAuth
import KakaoSDKUser
import RxSwift
import Foundation

protocol KakaoAuthManagerProtocol {
    func signInWithKakao() -> Observable<KakaoAuthResult>
}

final class KakaoAuthManager: KakaoAuthManagerProtocol {
    func signInWithKakao() -> Observable<KakaoAuthResult> {
        return Observable.create { observer in
            // 카카오톡 설치 여부 확인
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                    if let error = error {
                        observer.onError(error)
                        return
                    }
                    
                    if let token = oauthToken {
                        self.getUserInfo(token: token.accessToken, observer: observer)
                    }
                }
            } else {
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                    if let error = error {
                        observer.onError(error)
                        return
                    }
                    
                    if let token = oauthToken {
                        self.getUserInfo(token: token.accessToken, observer: observer)
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    // 사용자 정보 요청 메서드 개선
    private func getUserInfo(token: String, observer: AnyObserver<KakaoAuthResult>) {
        UserApi.shared.me() { user, error in
            if let error = error {
                observer.onError(error)
                return
            }
            
            guard let userId = user?.id else {
                observer.onError(NSError(domain: "KakaoLogin", code: -2, userInfo: [NSLocalizedDescriptionKey: "사용자 ID를 가져올 수 없습니다."]))
                return
            }
            
            // 사용자 ID를 문자열로 변환하고 로그 추가
            let userIdString = "\(userId)"
            
            // 닉네임 정보 추가 (있는 경우)
            let nickname = user?.kakaoAccount?.profile?.nickname
            
            // Kakao 로그인 성공 후 반환 및 세션 저장
            observer.onNext(KakaoAuthResult(token: token, userId: userIdString, nickname: nickname))
            AppSessionManager.shared.saveKakaoSession(userId: userIdString)
            observer.onCompleted()
        }
    }
}

// KakaoAuthResult 구조체
struct KakaoAuthResult {
    let token: String
    let userId: String
    let nickname: String?
}
