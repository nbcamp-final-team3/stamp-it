//
//  FCMManager.swift
//  StampIt-Project
//
//  Created by 윤주형 on 7/29/25.
//

import Foundation
import Firebase
import FirebaseMessaging
import RxSwift

final class FCMManager: NSObject, FCMManagerProtocol {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    override init() {
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
        // Firestore 직접 업데이트
        return Observable.create { observer in
            let db = Firestore.firestore()
            db.collection("users").document(userId).updateData(["fcmToken": token]) { error in
                if error != nil {
                    observer.onError(FCMError.tokenUpdateFailed)
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func getFCMTokenFromUser(userId: String) -> Observable<String?> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            db.collection("users").document(userId).getDocument { document, error in
                if error != nil {
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }
                
                if let data = document?.data(),
                   let fcmToken = data["fcmToken"] as? String {
                    observer.onNext(fcmToken)
                } else {
                    observer.onNext(nil)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    // MARK: - 그룹 멤버 FCM 토큰만 조회
    func getGroupMemberFCMTokens(groupId: String) -> Observable<[String]> {
        return Observable.create { observer in
            let db = Firestore.firestore()
            print("🔍 FCM 토큰 조회 시작: 그룹 \(groupId)")
            
            let query = db.collection("users").whereField("groupId", isEqualTo: groupId)  // 🎯 groupID → groupId로 수정
            print("📝 쿼리 실행: users 컬렉션에서 groupId = \(groupId)인 사용자들 조회")
            
            query.getDocuments { snapshot, error in
                if let error = error {
                    print("❌ FCM 토큰 조회 실패: \(error)")
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                guard let snapshot = snapshot else {
                    print("⚠️ 스냅샷이 nil: 문서가 존재하지 않음")
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                print("📊 조회된 사용자 수: \(snapshot.documents.count)명")
                
                let tokens = snapshot.documents.compactMap { document in
                    let userId = document.documentID
                    let data = document.data()
                    let fcmToken = data["fcmToken"] as? String
                    let nickname = data["nickname"] as? String ?? "Unknown"
                    
                    if let token = fcmToken {
                        print("✅ 사용자 \(nickname) (\(userId)): FCM 토큰 있음")
                        return token
                    } else {
                        print("⚠️ 사용자 \(nickname) (\(userId)): FCM 토큰 없음")
                        return nil
                    }
                }
                
                print("🎯 최종 FCM 토큰 수: \(tokens.count)개")
                if tokens.isEmpty {
                    print("🚨 경고: 그룹 \(groupId)의 모든 멤버에게 FCM 토큰이 없음")
                } else {
                    print("✅ 성공: 그룹 \(groupId)의 \(tokens.count)명에게 FCM 토큰 확인됨")
                }
                
                observer.onNext(tokens)
                observer.onCompleted()
            }
            return Disposables.create()
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
