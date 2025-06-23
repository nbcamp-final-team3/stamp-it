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
    
    init(editProfileRepositoryImpl: EditProfileRepository) {
        self.editProfileRepositoryImpl = editProfileRepositoryImpl
    }
    
    // 닉네임 업데이트
    func updateUserNickname(userId: String, groupId: String, nickname: String, changedAt: Date) -> RxSwift.Observable<Void> {
        editProfileRepositoryImpl.updateUserNickname(userId: userId, groupId: groupId, nickname: nickname, changedAt: changedAt)
    }
    
    // 그룹명 업데이트
    func updateGroupName(groupId: String, name: String, changedAt: Date) -> Observable<Void> {
        editProfileRepositoryImpl.updateGroupName(groupId: groupId, groupName: name, changedAt: changedAt)
    }
    
    // 프로필 이미지 업데이트
    func updateProfileImage(userId: String, groupId: String, imageName: String) -> Observable<Void> {
        editProfileRepositoryImpl.updateProfileImage(userId: userId, groupId: groupId, imageName: imageName)
    }
}
