//
//  EditProfileRepository.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/17/25.
//

import Foundation
import RxSwift

protocol EditProfileRepository {
    /// 닉네임 업데이트
    /// - Parameters:
    ///   - userId: 유저 ID 정보
    ///   - nickname: 새로운 닉네임
    ///   - changedAt: 닉네임 변경 시기
    /// - Returns: Observable(Void)
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void>
    
    /// 그룹명 업데이트: 그룹장만 가능(User 정보 중 isLeader == true)
    /// - Parameters:
    ///   - groupId: 그룹 ID 정보
    ///   - groupName: 새로운 그룹명
    ///   - changedAt: 그룹명 변경 시기
    /// - Returns: Observable(Void)
    func updateGroupName(groupId: String, groupName: String, changedAt: Date) -> Observable<Void>
    
    /// 프로필 이미지 업데이트(에셋에 있는 8가지 중에서만 선택 가능)
    /// - Parameters:
    ///   - userId: 유저 ID 정보
    ///   - imageName: 새로운 이미지 에셋 이름
    /// - Returns: Observable(Void)
    func updateProfileImage(userId: String, imageName: String) -> Observable<Void>
}
