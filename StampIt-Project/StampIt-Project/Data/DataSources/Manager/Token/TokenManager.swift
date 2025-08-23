//
//  TokenManager.swift
//  StampIt-Project
//
//  Created by 윤주형 on 8/23/25.
//

import Foundation
import FirebaseFirestore
import RxSwift

final class TokenManager: TokenManagerProtocol {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let disposeBag = DisposeBag()
    
    // MARK: - Collection Reference
    var tokensCollection: CollectionReference {
        return db.collection("tokens")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - Token Management
    
    /// 사용자의 FCM 토큰 저장/업데이트
    func saveOrUpdateToken(userId: String, fcmToken: String) -> Observable<Void> {
        return Observable.create { observer in
            // 기존 토큰이 있는지 확인
            self.tokensCollection
                .whereField("userId", isEqualTo: userId)
                .getDocuments { [weak self] snapshot, error in
                    if let error = error {
                        observer.onError(TokenError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    if let documents = snapshot?.documents, !documents.isEmpty {
                        // 기존 토큰이 있으면 업데이트
                        self?.updateExistingToken(documents: documents, newToken: fcmToken, observer: observer)
                    } else {
                        // 새 토큰 생성
                        self?.createNewToken(userId: userId, fcmToken: fcmToken, observer: observer)
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// 기존 토큰 업데이트
    private func updateExistingToken(
        documents: [QueryDocumentSnapshot],
        newToken: String,
        observer: AnyObserver<Void>
    ) {
        let batch = db.batch()
        
        // 기존 토큰들을 삭제
        for document in documents {
            batch.deleteDocument(document.reference)
        }
        
        // 새 토큰 생성
        let userId = documents.first?.data()["userId"] as? String ?? ""
        let newTokenDoc = TokenFirestore(
            tokenId: "\(userId)_\(UUID().uuidString.prefix(8))",
            userId: userId,
            fcmToken: newToken
        )
        let newTokenRef = tokensCollection.document(newTokenDoc.documentID)
        
        do {
            try batch.setData(from: newTokenDoc, forDocument: newTokenRef)
        } catch {
            observer.onError(TokenError.encodingFailed(error.localizedDescription))
            return
        }
        
        batch.commit { error in
            if let error = error {
                observer.onError(TokenError.updateFailed(error.localizedDescription))
            } else {
                observer.onNext(())
                observer.onCompleted()
            }
        }
    }
    
    /// 새 토큰 생성
    private func createNewToken(
        userId: String,
        fcmToken: String,
        observer: AnyObserver<Void>
    ) {
        let newTokenDoc = TokenFirestore(
            tokenId: "\(userId)_\(UUID().uuidString.prefix(8))",
            userId: userId,
            fcmToken: fcmToken
        )
        
        do {
            try tokensCollection.document(newTokenDoc.documentID).setData(from: newTokenDoc) { error in
                if let error = error {
                    observer.onError(TokenError.createFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
        } catch {
            observer.onError(TokenError.encodingFailed(error.localizedDescription))
        }
    }
    
    /// 사용자의 FCM 토큰 조회
    func getActiveToken(userId: String) -> Observable<String?> {
        return Observable.create { observer in
            self.tokensCollection
                .whereField("userId", isEqualTo: userId)
                .limit(to: 1)
                .getDocuments { snapshot, error in
                    if let error = error {
                        observer.onError(TokenError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    if let document = snapshot?.documents.first,
                       let token = document.data()["fcmToken"] as? String {
                        observer.onNext(token)
                    } else {
                        observer.onNext(nil)
                    }
                    observer.onCompleted()
                }
            
            return Disposables.create()
        }
    }
    
    /// 그룹 멤버들의 FCM 토큰 조회
    func getGroupMemberActiveTokens(groupId: String) -> Observable<[String]> {
        return Observable.create { observer in
            // 그룹 멤버십을 통해 사용자 ID들을 조회
            let membershipsRef = self.db.collection("memberships")
                .whereField("groupId", isEqualTo: groupId)
            
            membershipsRef.getDocuments { [weak self] snapshot, error in
                if let error = error {
                    observer.onError(TokenError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                let userIds = documents.compactMap { doc -> String? in
                    return doc.data()["userId"] as? String
                }
                
                if userIds.isEmpty {
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                // 각 사용자의 토큰 조회
                self?.getTokensForUsers(userIds: userIds, observer: observer)
            }
            
            return Disposables.create()
        }
    }
    
    /// 여러 사용자의 토큰 조회
    private func getTokensForUsers(
        userIds: [String],
        observer: AnyObserver<[String]>
    ) {
        let tokensRef = tokensCollection
            .whereField("userId", in: userIds)
        
        tokensRef.getDocuments { snapshot, error in
            if let error = error {
                observer.onError(TokenError.fetchFailed(error.localizedDescription))
                return
            }
            
            let tokens = snapshot?.documents.compactMap { doc -> String? in
                return doc.data()["fcmToken"] as? String
            } ?? []
            
            observer.onNext(tokens)
            observer.onCompleted()
        }
    }
    
    /// 사용자의 모든 토큰 삭제 (계정 삭제 시)
    func deleteAllTokens(userId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.tokensCollection
                .whereField("userId", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        observer.onError(TokenError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    let batch = self.db.batch()
                    
                    snapshot?.documents.forEach { document in
                        batch.deleteDocument(document.reference)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            observer.onError(TokenError.deleteFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                }
            
            return Disposables.create()
        }
    }
}
