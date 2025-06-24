//
//  EditProfileRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/17/25.
//

import Foundation
import RxSwift

final class EditProfileRepositoryImpl: EditProfileRepository {
    private let userManager: UserManager
    private let groupManager: GroupManager
    private let membershipManager: MembershipManager
    
    init(
            userManager: UserManager,
            groupManager: GroupManager,
            membershipManager: MembershipManager,
        ) {
            self.userManager = userManager
            self.groupManager = groupManager
            self.membershipManager = membershipManager
        }
    
    // 닉네임 업데이트
    func updateUserNickname(userId: String, groupId: String, nickname: String, changedAt: Date) -> Observable<Void> {
        // 1. users 컬렉션 업데이트
        let updateUser = userManager.updateUserNickname(
            userId: userId,
            nickname: nickname,
            changedAt: changedAt
        )
        
        // 2. memberships 컬렉션 업데이트
        let updateMembership = membershipManager.updateMemberNickname(
            groupId: groupId,
            userId: userId,
            nickname: nickname
        )
        
        // 두 작업을 병렬로 실행
        return Observable.zip(updateUser, updateMembership)
            .map { _ in () }
            .catch { [weak self] error in
                guard self != nil else {
                    return Observable.error(RepositoryError.unknownError)
                }
                return Observable.error(error)
            }
    }
    
    // 그룹명 업데이트
    func updateGroupName(groupId: String, groupName: String, changedAt: Date) -> Observable<Void> {
        return groupManager.updateGroupName(
            groupId: groupId,
            name: groupName,
            changedAt: changedAt
        )
    }
    
    // 프로필 이미지 업데이트
    func updateProfileImage(userId: String, groupId: String, imageName: String) -> Observable<Void> {
            // 1. users 컬렉션 업데이트
            let updateUser = userManager.updateProfileImage(
                userId: userId,
                imageName: imageName
            )
            
            // 2. memberships 컬렉션 업데이트
            let updateMembership = membershipManager.updateMemberProfileImage(
                groupId: groupId,
                userId: userId,
                profileImage: imageName
            )
            
            // 두 작업을 병렬로 실행
            return Observable.zip(updateUser, updateMembership)
                .map { _ in () }
                .catch { [weak self] error in
                    guard self != nil else {
                        return Observable.error(RepositoryError.unknownError)
                    }
                    return Observable.error(error)
                }
        }
}
