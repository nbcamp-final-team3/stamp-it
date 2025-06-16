//
//  SendInviteRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift
import FirebaseCore

final class SendInviteRepositoryImpl: SendInviteRepository {

    private let firestoreManager: FirestoreManagerProtocol
    private let authRepository: AuthRepositoryProtocol

    init(firestoreManager: FirestoreManagerProtocol = FirestoreManager(),
         authRepository: AuthRepositoryProtocol = AuthRepository(authManager: AuthManager(), firestoreManager: FirestoreManager())) {
        self.firestoreManager = firestoreManager
        self.authRepository = authRepository
    }

    func fetchUserOnce(userId: String) -> Observable<UserFirestore> {
        return firestoreManager.fetchUserOnce(userId: userId)
    }

    func createInvite(_ invite: InviteFirestore) -> Observable<Void>{
        return firestoreManager.createInvite(invite)
    }

    func fetchGroup(groupId: String) -> Observable<GroupFirestore> {
        return firestoreManager.fetchGroup(groupId: groupId)
    }

    func getCurrentUser() -> Observable<StampIt_Project.User?> {
        return authRepository.getCurrentUser()
    }

    func sequenceCreateCode() -> Observable<String> {
        return getCurrentUser()
            .flatMap { user -> Observable<UserFirestore> in
                guard let user = user else {
                    return Observable.error(FirestoreError.createFailed("사용자 정보 없음"))
                }
                return self.fetchUserOnce(userId: user.userID)
            }
            .flatMap { userFirestore -> Observable<(UserFirestore, GroupFirestore)> in
                return self.fetchGroup(groupId: userFirestore.groupId)
                    .map { group in
                        (userFirestore, group)
                    }
            }
            .flatMap { userFirestore, groupFirestore -> Observable<String> in
                let now = Timestamp(date: Date())
                let expired = Timestamp(date: Date().addingTimeInterval(60 * 60 * 24)) // 24시간 뒤

                let invite = InviteFirestore(
                    inviteCode: groupFirestore.inviteCode,
                    groupId: userFirestore.groupId,
                    createdBy: userFirestore.userId,
                    createdAt: now,
                    expiredAt: expired
                )

                return self.createInvite(invite)
                    .map { invite.inviteCode }
            }
    }
}
