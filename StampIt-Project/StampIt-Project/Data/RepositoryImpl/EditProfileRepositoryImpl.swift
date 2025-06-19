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
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void> {
        firestoreManager.updateUserNickname(
            userId: userId,
            nickname: nickname,
            changedAt: changedAt
        )
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
    func updateProfileImage(userId: String, imageName: String) -> Observable<Void> {
        firestoreManager.updateProfileImage(
            userId: userId,
            imageName: imageName
        )
    }
}
