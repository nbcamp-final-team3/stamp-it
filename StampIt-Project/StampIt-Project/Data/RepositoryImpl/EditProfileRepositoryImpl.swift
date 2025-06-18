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
    
    init(firestoreManager: FirestoreManagerProtocol = FirestoreManager()) {
        self.firestoreManager = firestoreManager
    }
    
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void> {
        firestoreManager.updateUserNickname(
            userId: userId,
            nickname: nickname,
            changedAt: changedAt
        )
    }
    
    func updateGroupName(groupId: String, groupName: String, changedAt: Date) -> Observable<Void> {
        firestoreManager.updateGroupName(
            groupId: groupId,
            name: groupName,
            changedAt: changedAt
        )
    }
    
    func updateProfileImage(userId: String, imageName: String) -> Observable<Void> {
        firestoreManager.updateProfileImage(
            userId: userId,
            imageName: imageName
        )
    }
}
