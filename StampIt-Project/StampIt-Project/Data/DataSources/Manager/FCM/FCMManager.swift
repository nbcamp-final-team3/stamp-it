//
//  FCMManager.swift
//  StampIt-Project
//
//  Created by 윤주형 on 7/29/25.
//

import Foundation
import Firebase
import FirebaseMessaging
import FirebaseFirestore
import RxSwift

final class FCMManager: NSObject, FCMManagerProtocol {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let db = Firestore.firestore()
    
    // MARK: - Init
    override init() {
        super.init()
    }
    
    // MARK: - FCM 토큰 관리
//    func getFCMToken() -> Observable<String> {
//        return Observable.create { observer in
//            Messaging.messaging().token { token, error in
//                if error != nil {
//                    observer.onError(FCMError.tokenRetrievalFailed)
//                    return
//                }
//                
//                guard let token = token else {
//                    observer.onError(FCMError.tokenRetrievalFailed)
//                    return
//                }
//                
//                observer.onNext(token)
//                observer.onCompleted()
//            }
//            
//            return Disposables.create()
//        }
//    }
    
    // MARK: - 단순한 토큰 upsert
    func upsertToken(_ token: String, for userId: String) {
        // 사용자별로 고정된 문서 ID 사용 (같은 토큰일 경우 갱신만)
        let doc = db.collection("tokens").document(userId)
        
        let payload: [String: Any] = [
            "userId": userId,
            "fcmToken": token,
            "tokenId": userId,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        doc.setData(payload, merge: true) { error in
            if let error = error {
                print("❌ FCM token upsert 실패: \(error)")
            } else {
                print("✅ FCM token upsert 성공 - 사용자: \(userId)")
            }
        }
    }
    
    // MARK: - 기존 메서드들 (하위 호환성)
//    func refreshFCMTokenForUser(userId: String) -> Observable<Void> {
//        return getFCMToken()
//            .flatMap { [weak self] (token: String) -> Observable<Void> in
//                guard self != nil else {
//                    return Observable.error(FCMError.unknownError)
//                }
//                return DIContainer.shared.tokenManager.saveOrUpdateToken(userId: userId, fcmToken: token)
//            }
//    }
}
