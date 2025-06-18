//
//  EditProfileUseCaseImpl.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/17/25.
//

import Foundation
import RxSwift

struct EditProfileUseCaseImpl: EditProfileUseCase {
    private let editProfileRepositoryImpl: EditProfileRepository
    
    init(editProfileRepositoryImpl: EditProfileRepository = EditProfileRepositoryTest()) {
        self.editProfileRepositoryImpl = editProfileRepositoryImpl
    }
    
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> RxSwift.Observable<Void> {
        editProfileRepositoryImpl.updateUserNickname(userId: userId, nickname: nickname, changedAt: changedAt)
    }
    
    func updateGroupName(groupId: String, name: String, changedAt: Date) -> Observable<Void> {
        editProfileRepositoryImpl.updateGroupName(groupId: groupId, groupName: name, changedAt: changedAt)
    }
    
    func updateProfileImage(userId: String, imageName: String) -> Observable<Void> {
        editProfileRepositoryImpl.updateProfileImage(userId: userId, imageName: imageName)
    }
}
