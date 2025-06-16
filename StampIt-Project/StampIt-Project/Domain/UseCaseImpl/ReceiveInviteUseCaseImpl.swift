//
//  ReceiveInviteUseCaseImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/16/25.
//

import Foundation
import RxSwift
import FirebaseCore

final class ReceiveInviteUseCaseImpl: ReceiveInviteUseCase {


    //fb authrepo
    private let authRepository: AuthRepositoryProtocol

    //fb manager를 사용하는 repo
    private let receiveInviteRepository: ReceiveInviteRepository

    init(authRepository: AuthRepositoryProtocol,
         receiveInviteRepository: ReceiveInviteRepository) {
        self.authRepository = authRepository
        self.receiveInviteRepository = receiveInviteRepository
    }

    func getCurrentUser() -> Observable<StampIt_Project.User?> {
        authRepository.getCurrentUser()
    }

    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void> {
        authRepository.addMember(groupId: groupId, member: member)
    }

    func receiveInvite(withCode inviteCode: String) -> Observable<InviteFirestore> {
        return authRepository.getCurrentUser()
            .flatMap { user -> Observable<InviteFirestore> in
                guard let currentUser = user else {
                    return Observable.error(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "로그인이 필요합니다"]))
                }
                return self.receiveInviteRepository.fetchInvite(inviteCode: inviteCode)
                    .flatMap { invite in
                        return self.receiveInviteRepository.fetchUserOnce(userId: currentUser.userID)
                            .flatMap { userFirestore in
                                // 4. 새 멤버 생성 후 추가
                                let newMember = MemberFirestore(
                                    userId: userFirestore.userId,
                                    nickname: userFirestore.nickname,
                                    joinedAt: Timestamp(),
                                    isLeader: false
                                )
                                return self.receiveInviteRepository.addMember(groupId: invite.groupId, member: newMember).map { invite }
                            }
                    }
            }
    }
}
