//
//  Invite.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift

final class InviteUseCaseImpl: InviteUseCase {


    private let authRepository: AuthRepositoryProtocol
    private let inviteRepository: InviteRepository

    init(authRepository: AuthRepositoryProtocol, inviteRepository: InviteRepository) {
        self.authRepository = authRepository
        self.inviteRepository = inviteRepository
    }

    // 공통 메서드
    func getCurrentUser() -> Observable<User?> {
        authRepository.getCurrentUser()
    }

    func fetchUserOnce(userId: String) -> Observable<User> {
        inviteRepository.fetchUserOnce(userId: userId)
    }

    // receive 관련 메서드
    func addMember(groupId: String, member: Member) -> Observable<Void> {
        let toDomain = member.toFirestoreModel()
        return authRepository.addMember(groupId: groupId, member: toDomain)
    }

    // send 관련 메서드
    func fetchGroup(groupId: String) -> Observable<Group> {
        inviteRepository.fetchGroup(groupId: groupId)
    }

    func createInvite(_ invite: Invitation) -> Observable<Void> {
        inviteRepository.createInvite(invite)
    }

    func fetchInvite(inviteCode: String) -> Observable<Invitation> {
        inviteRepository.fetchInvite(inviteCode: inviteCode)
    }

    // 6/ 17 추가 메서드
    /// 초대코드로 그룹 정보 가져오기
    func fetchGroupByInviteCode(inviteCode: String) -> Observable<Group> {
        inviteRepository.fetchGroupByInviteCode(inviteCode: inviteCode)
    }

    /// 그룹의 멤버 수 확인
    func fetchGroupMemberCount(groupId: String) -> Observable<Int> {
        inviteRepository.fetchGroupMemberCount(groupId: groupId)
    }

    // 초대받아서 성공 했을 경우에 가지고 있던 그룹 삭제 처리 (1인 그룹일 경우)
    /// 그룹 삭제
    func deleteGroup(groupId: String) -> Observable<Void> {
        inviteRepository.deleteGroup(groupId: groupId)
    }

    func switchUserGroup(userId: String, fromGroupId: String, toGroupId: String, userNickname: String) -> Observable<Void> {
        inviteRepository.switchUserGroup(userId: userId, fromGroupId: fromGroupId, toGroupId: toGroupId, userNickname: userNickname)
    }

    /// 초대코드를 받아서 해당 그룹에 새 멤버를 추가하는 코드
    func acceptInvite(inviteCode: String) -> Observable<Invitation> {
        //본인이 db에 추가가 됐는지 확인
        return getCurrentUser()
            .flatMap { [weak self] optionalUser -> Observable<(User, Invitation)> in
                guard let self = self, let user = optionalUser else {
                    return Observable.error(RepositoryError.userNotFound)
                }
                return self.fetchInvite(inviteCode: inviteCode)
                    .map { invite in
                        if invite.expiredAt < Date() {
                            throw RepositoryError.expiredInviteCode
                        }
                        if invite.groupID == user.groupID {
                            throw RepositoryError.alreadyInGroup
                        }
                        return (user, invite)
                    }
            }
            .flatMap { [weak self] user, invite -> Observable<(User, Group)> in
                guard let self = self else { return .empty() }

                return self.fetchGroupByInviteCode(inviteCode: inviteCode)
                    .map { group in (user, group) }
            }
            .flatMap { [weak self] user, group -> Observable<(User, Group, User)> in
                guard let self = self else { return .empty() }
                return self.fetchUserOnce(userId: user.userID)
                    .map { user in (user, group, user) }
            }
            .flatMap { [weak self] user, group, fetchUser -> Observable<(User, Group, User, Int)> in
                guard let self = self else { return .empty() }
                return self.fetchGroupMemberCount(groupId: group.groupID)
                    .map { count in (user, group, fetchUser, count) }
            }
            .flatMap { [weak self] user, group, fetchUser, memberCount -> Observable<Invitation> in
                guard let self = self else { return .empty() }

                guard memberCount < 10 else {
                    return .error(RepositoryError.groupIsFull)
                }

                let oldGroupId = fetchUser.groupID
                let newGroupId = group.groupID

                return self.fetchGroupMemberCount(groupId: oldGroupId)
                    .flatMap { oldGroupMemberCount -> Observable<Void> in
                        if oldGroupMemberCount == 1 {
                            return self.deleteGroup(groupId: oldGroupId)
                        } else {
                            return .just(())
                        }
                    }
                    .flatMap {
                        self.switchUserGroup(
                            userId: user.userID,
                            fromGroupId: oldGroupId,
                            toGroupId: newGroupId,
                            userNickname: user.nickname
                        )
                    }
                    .flatMap {
                        self.fetchInvite(inviteCode: inviteCode)
                    }
            }
    }
    /// 초대 코드를 확인하는 코드
    func getInviteCode() -> Observable<String> {
        return getCurrentUser()
            .flatMap { optionalUser -> Observable<User> in
                guard let user = optionalUser else {
                    return Observable.error(RepositoryError.userNotFound)
                }
                return self.fetchUserOnce(userId: user.userID)
            }
            .flatMap { user -> Observable<Group> in
                return self.fetchGroup(groupId: user.groupID)
            }
            .map { group in
                return group.inviteCode
            }
    }

 
}

