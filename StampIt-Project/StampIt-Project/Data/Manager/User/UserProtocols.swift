//
//  UserProtocols.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

protocol UserManagerProtocol {
    // 기본 CRUD
    func fetchUserOnce(userId: String) -> Observable<UserFirestore>
    func fetchUser(userId: String) -> Observable<UserFirestore>
    func createUser(_ user: UserFirestore) -> Observable<Void>
    func updateUser(_ user: UserFirestore) -> Observable<Void>
    func deleteUser(userId: String) -> Observable<Void>
    
    // 편의 업데이트 메서드들
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void>
    func updateProfileImage(userId: String, imageName: String) -> Observable<Void>
    func updateUserGroupId(userId: String, newGroupId: String) -> Observable<Void>
}
