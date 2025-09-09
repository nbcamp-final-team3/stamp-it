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
    
    // MARK: - 단순한 토큰 upsert
    func upsertToken(_ token: String, for userId: String) {
        // 사용자별로 고정된 문서 ID 사용 (같은 토큰일 경우 갱신만)
        let doc = db.collection("tokens").document(userId)
        
        // TokenFirestore 모델 생성
        let tokenData = TokenFirestore(
            userId: userId,
            fcmToken: token
        )
        
        do {
            try doc.setData(from: tokenData, merge: true) { error in
                if let error = error {
                    print("❌ FCM token upsert 실패: \(error)")
                } else {
                    print("✅ FCM token upsert 성공 - 사용자: \(userId)")
                }
            }
        } catch {
            print("❌ FCM token 모델 인코딩 실패: \(error)")
        }
    }
}
