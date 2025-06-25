//
//  UserManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import RxSwift

final class UserManager: UserManagerProtocol {
    typealias Entity = UserFirestore
    typealias ID = String
    typealias Query = UserQuery
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - FullCRUDRepository 프로토콜 구현
    func fetch(id: String) -> Observable<UserFirestore?> {
        return fetchUserOnce(userId: id)
            .map { user -> UserFirestore? in user }
            .catchAndReturn(nil)
    }
    
    func observe(id: String) -> Observable<UserFirestore?> {
        return fetchUser(userId: id)
            .map { user -> UserFirestore? in user }
            .catchAndReturn(nil)
    }
    
    func create(_ entity: UserFirestore) -> Observable<Void> {
        return createUser(entity)
    }
    
    func update(id: String, entity: UserFirestore) -> Observable<Void> {
        guard id == entity.documentID else {
            return Observable.error(UserError.invalidInput("ID 불일치"))
        }
        return updateUser(entity)
    }
    
    func updateFields(id: String, fields: [String: Any]) -> Observable<Void> {
        return Observable.create { observer in
            self.usersCollection.document(id).updateData(fields) { error in
                if let error = error {
                    observer.onError(UserError.updateFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func delete(id: String) -> Observable<Void> {
        return deleteUser(userId: id)
    }
    
    func fetchList(query: UserQuery) -> Observable<[UserFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.usersCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            firestoreQuery.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(UserError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                do {
                    let users = try documents.compactMap { document in
                        try document.data(as: UserFirestore.self)
                    }
                    observer.onNext(users)
                    observer.onCompleted()
                } catch {
                    observer.onError(UserError.decodingFailed(error.localizedDescription))
                }
            }
            return Disposables.create()
        }
    }
    
    func observeList(query: UserQuery) -> Observable<[UserFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.usersCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            let listener = firestoreQuery.addSnapshotListener { snapshot, error in
                if let error = error {
                    observer.onError(UserError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    return
                }
                
                do {
                    let users = try documents.compactMap { document in
                        try document.data(as: UserFirestore.self)
                    }
                    observer.onNext(users)
                } catch {
                    observer.onError(UserError.decodingFailed(error.localizedDescription))
                }
            }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    // MARK: - Private Helper
    private func applyQueryConditions(_ query: FirebaseFirestore.Query, query userQuery: UserQuery) -> FirebaseFirestore.Query {
        var result = query
        
        if let userIds = userQuery.userIds, !userIds.isEmpty {
            result = result.whereField("userId", in: userIds)
        }
        
        if let groupIds = userQuery.groupIds, !groupIds.isEmpty {
            result = result.whereField("groupId", in: groupIds)
        }
        
        if let nicknameContains = userQuery.nicknameContains, !nicknameContains.isEmpty {
            result = result.whereField("nickname", isGreaterThanOrEqualTo: nicknameContains)
                .whereField("nickname", isLessThan: nicknameContains + "\u{f8ff}")
        }
        
        if let createdAfter = userQuery.createdAfter {
            result = result.whereField("createdAt", isGreaterThan: Timestamp(date: createdAfter))
        }
        
        if let QueryOrder = userQuery.QueryOrder {
            result = result.order(by: QueryOrder.field, descending: QueryOrder.descending)
        }
        
        if let limit = userQuery.limit {
            result = result.limit(to: limit)
        }
        
        return result
    }
    
    // MARK: - 기존 FirestoreManager 메서드들 (하위 호환성)
    
    /// 사용자 정보 일회성 조회 (로그인용)
    func fetchUserOnce(userId: String) -> Observable<UserFirestore> {
        return Observable.create { observer in
            self.usersCollection.document(userId)
                .getDocument(source: .server) { documentSnapshot, error in
                    if let error = error {
                        observer.onError(UserError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onError(UserError.userNotFound)
                        return
                    }
                    
                    do {
                        let user = try document.data(as: UserFirestore.self)
                        observer.onNext(user)
                        observer.onCompleted()
                    } catch {
                        observer.onError(UserError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// 사용자 정보 실시간 조회 (스냅샷 리스너)
    func fetchUser(userId: String) -> Observable<UserFirestore> {
        return Observable.create { observer in
            let listener = self.usersCollection.document(userId)
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        observer.onError(UserError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onError(UserError.userNotFound)
                        return
                    }
                    
                    do {
                        let user = try document.data(as: UserFirestore.self)
                        observer.onNext(user)
                    } catch {
                        observer.onError(UserError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    /// 새 사용자 생성
    func createUser(_ user: UserFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.usersCollection.document(user.documentID)
                    .setData(from: user) { error in
                        if let error = error {
                            observer.onError(UserError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(UserError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 사용자 정보 업데이트
    func updateUser(_ user: UserFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.usersCollection.document(user.documentID)
                    .setData(from: user, merge: true) { error in
                        if let error = error {
                            observer.onError(UserError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(UserError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 사용자 삭제 (사용자 문서 삭제 (사용자 탈퇴에 사용))
    func deleteUser(userId: String) -> Observable<Void> {
        return Observable.create { observer in
            let userRef = self.usersCollection.document(userId)
            userRef.delete { error in
                if let error = error {
                    observer.onError(UserError.deleteFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    /// 닉네임 업데이트
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void> {
        return Observable.create { observer in
            self.usersCollection.document(userId).updateData([
                "nickname": nickname,
                "nicknameChangedAt": Timestamp(date: changedAt)
            ]) { error in
                if let error = error {
                    observer.onError(UserError.updateFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    /// 프로필 이미지 업데이트
    func updateProfileImage(userId: String, imageName: String) -> Observable<Void> {
        return Observable.create { observer in
            self.usersCollection.document(userId).updateData([
                "profileImage": imageName
            ]) { error in
                if let error = error {
                    observer.onError(UserError.updateFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    /// 사용자의 groupId 업데이트
    func updateUserGroupId(userId: String, newGroupId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.usersCollection.document(userId).updateData([
                "groupId": newGroupId
            ]) { error in
                if let error = error {
                    observer.onError(UserError.updateFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}
