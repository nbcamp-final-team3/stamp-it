//
//  EditProfileRepositoryTest.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/18/25.
//

import Foundation
import RxSwift

// EditProfileRepositoryImpl 테스트 클래스
final class EditProfileRepositoryTest: EditProfileRepository {
    private let firestoreManager: FirestoreManagerProtocol
    
    init(firestoreManager: FirestoreManagerProtocol = FirestoreManager()) {
        self.firestoreManager = firestoreManager
    }
    
    // 닉네임 업데이트
    func updateUserNickname(userId: String, groupId: String, nickname: String, changedAt: Date) -> Observable<Void> {
        print("Firestore nickname update success: \(userId), \(nickname), \(changedAt)")
        return Observable.create { observer in
            observer.on(.next(()))
            observer.on(.completed)
            return Disposables.create()
        }
    }
    
    // 그룹명 업데이트
    func updateGroupName(groupId: String, groupName: String, changedAt: Date) -> Observable<Void> {
        print("Firestore group name update success: \(groupId), \(groupName), \(changedAt)")
        return Observable.create { observer in
            observer.on(.next(()))
            observer.on(.completed)
            return Disposables.create()
        }
    }
    
    // 프로필 이미지 업데이트
    func updateProfileImage(userId: String, groupId: String, imageName: String) -> Observable<Void> {
        print("Firestore profile image update success: \(userId), \(imageName)")
        return Observable.create { observer in
            observer.on(.next(()))
            observer.on(.completed)
            return Disposables.create()
        }
    }
}
