//
//  EditProfileRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/17/25.
//

import Foundation
import RxSwift

final class EditProfileRepositoryImpl: EditProfileRepository {
    private let firestoreManager: FirestoreManagerProtocol
    
    init(firestoreManager: FirestoreManagerProtocol) {
        self.firestoreManager = firestoreManager
    }
    
    // 닉네임 업데이트
    func updateUserNickname(userId: String, groupId: String, nickname: String, changedAt: Date) -> Observable<Void> {
        let updateUser = firestoreManager.updateUserNickname(
            userId: userId,
            nickname: nickname,
            changedAt: changedAt
        )

        let updateMember = firestoreManager.updateMember(
            groupId: groupId,
            userId: userId,
            query: ["nickname": nickname]
        )

        return Observable.zip(updateUser, updateMember)
            .map { _ in () }
    }
    
    // 그룹명 업데이트
    func updateGroupName(groupId: String, groupName: String, changedAt: Date) -> Observable<Void> {
        firestoreManager.updateGroupName(
            groupId: groupId,
            name: groupName,
            changedAt: changedAt
        )
    }
    
    // 프로필 이미지 업데이트
    func updateProfileImage(userId: String, groupId: String, imageName: String) -> Observable<Void> {
        let updateUser = firestoreManager.updateProfileImage(
            userId: userId,
            imageName: imageName
        )

        let updateMember = firestoreManager.updateMember(
            groupId: groupId,
            userId: userId,
            query: ["profileImage": imageName]
        )

        return Observable.zip(updateUser, updateMember)
            .map { _ in () }
    }
}
