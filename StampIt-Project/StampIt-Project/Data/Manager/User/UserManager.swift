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
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    private var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - User Operations
    
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
