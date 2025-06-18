//
//  EditProfileUseCase.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/17/25.
//

import Foundation
import RxSwift

protocol EditProfileUseCase {
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void>
    func updateGroupName(groupId: String, name: String, changedAt: Date) -> Observable<Void>
    func updateProfileImage(userId: String, imageName: String) -> Observable<Void>
}
