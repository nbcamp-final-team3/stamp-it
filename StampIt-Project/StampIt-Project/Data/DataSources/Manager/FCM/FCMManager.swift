//
//  FCMManager.swift
//  StampIt-Project
//
//  Created by 윤주형 on 7/29/25.
//

import Foundation
import FirebaseMessaging
import RxSwift

final class FCMManager: NSObject, FCMManagerProtocol {
    
    // MARK: - Properties
    private let userManager: any UserManagerProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(userManager: any UserManagerProtocol) {
        self.userManager = userManager
        super.init()
        setupFCM()
    }
    
    // MARK: - FCM 설정
    private func setupFCM() {
        Messaging.messaging().delegate = self
    }
    
    // MARK: - FCM 토큰 관리
    func getFCMToken() -> Observable<String> {
        return Observable.create { observer in
            Messaging.messaging().token { token, error in
                if error != nil {
                    observer.onError(FCMError.tokenRetrievalFailed)
                    return
                }
                
                guard let token = token else {
                    observer.onError(FCMError.tokenRetrievalFailed)
                    return
                }
                
                observer.onNext(token)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - 토큰 갱신 (로그인 시 사용)
    func refreshFCMTokenForUser(userId: String) -> Observable<Void> {
        return getFCMToken()
            .flatMap { [weak self] (token: String) -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(FCMError.unknownError)
                }
                return self.saveFCMTokenToUser(userId: userId, token: token)
            }
    }
    
    // MARK: - 토큰 저장/조회
    func saveFCMTokenToUser(userId: String, token: String) -> Observable<Void> {
        return userManager.updateFields(id: userId, fields: ["fcmToken": token])
            .catch { error in
                return Observable.error(FCMError.tokenUpdateFailed)
            }
    }
    
    func getFCMTokenFromUser(userId: String) -> Observable<String?> {
        return userManager.fetch(id: userId)
            .map { user in
                return user?.fcmToken
            }
            .catch { _ in
                return Observable.just(nil)
            }
    }
    
    // MARK: - 그룹 멤버 FCM 토큰만 조회
    func getGroupMemberFCMTokens(groupId: String) -> Observable<[String]> {
        let query = UserQuery.byGroup(groupId)
        return userManager.fetchList(query: query)
            .map { users in
                return users.compactMap { $0.fcmToken }
            }
    }
}

// MARK: - MessagingDelegate
extension FCMManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        // 토큰이 갱신되면 현재 사용자에게 저장
        if let currentUser = UserCache.shared.getCurrentUser() {
            saveFCMTokenToUser(userId: currentUser.userID, token: token)
                .subscribe()
                .disposed(by: disposeBag)
        }
    }
} 
