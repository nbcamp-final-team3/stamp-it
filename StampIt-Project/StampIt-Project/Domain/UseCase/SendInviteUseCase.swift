//
//  1dqwd.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/13/25.
//

import Foundation
import RxSwift
import FirebaseFirestore

protocol CreateInviteUseCaseProtocol {
    func createInvite(groupId: String) -> Observable<String>
    func copyInviteCode(_ code: String) -> Observable<String>
}

final class CreateInviteUseCase: CreateInviteUseCaseProtocol {
    private let firestoreManager: FirestoreManager
    
    init(firestoreManager: FirestoreManager = .shared) {
        self.firestoreManager = firestoreManager
    }
    
    func createInvite(groupId: String) -> Observable<String> {
        let invite = InviteFirestore(
            inviteCode: groupId,
            groupId: groupId,
            createdBy: "currentUserId003", // TODO: 실제 현재 유저 ID로 교체
            createdAt: Timestamp(date: Date()),
            expiredAt: nil
        )
        
        return firestoreManager.createInvite(invite)
            .map { _ in groupId }
    }
    
    func copyInviteCode(_ code: String) -> Observable<String> {
        return Observable.create { observer in
            UIPasteboard.general.string = code
            observer.onNext("초대 코드가 복사되었습니다")
            observer.onCompleted()
            return Disposables.create()
        }
    }
} 
