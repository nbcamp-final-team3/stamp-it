//
//  UserProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

// MARK: - UserManager Protocol (기존 FirestoreManager 메서드 통합)
protocol UserManagerProtocol: FullCRUDRepository where Entity == UserFirestore, ID == String, Query == UserQuery {
    // 기본 CRUD
    func fetchUser(userId: String) -> Observable<UserFirestore>
    func fetchUserOnce(userId: String) -> Observable<UserFirestore>
    func createUser(_ user: UserFirestore) -> Observable<Void>
    func updateUser(_ user: UserFirestore) -> Observable<Void>
    func deleteUser(userId: String) -> Observable<Void>
    
    // 편의 업데이트 메서드들 (기존 FirestoreManager 메서드)
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void>
    func updateProfileImage(userId: String, imageName: String) -> Observable<Void>
    func updateUserGroupId(userId: String, newGroupId: String) -> Observable<Void>
}
