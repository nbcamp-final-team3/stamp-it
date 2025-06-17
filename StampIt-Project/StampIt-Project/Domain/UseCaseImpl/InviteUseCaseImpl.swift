//
//  Invite.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift
import FirebaseCore

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

    func fetchUserOnce(userId: String) -> Observable<UserFirestore> {
        inviteRepository.fetchUserOnce(userId: userId)
    }

    // receive 관련 메서드
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void> {
        authRepository.addMember(groupId: groupId, member: member)
    }

    func updateUser(_ user: UserFirestore) -> Observable<Void> {
        inviteRepository.updateUser(user)
    }

    // send 관련 메서드
    func fetchGroup(groupId: String) -> Observable<GroupFirestore> {
        inviteRepository.fetchGroup(groupId: groupId)
    }

    func createInvite(_ invite: InviteFirestore) -> Observable<Void> {
        inviteRepository.createInvite(invite)
    }

    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore> {
        inviteRepository.fetchInvite(inviteCode: inviteCode)
    }

    // 6/ 17 추가 메서드
    /// 초대코드로 그룹 정보 가져오기
    func fetchGroupByInviteCode(inviteCode: String) -> Observable<GroupFirestore> {
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
    func acceptInvite(inviteCode: String) -> Observable<InviteFirestore> {
        return getCurrentUser()
                .flatMap { [weak self] optionalUser -> Observable<(User, GroupFirestore)> in
                    guard let self = self, let user = optionalUser else {
                        return Observable.error(RepositoryError.userNotFound)
                    }
                    return self.fetchGroupByInviteCode(inviteCode: inviteCode)
                        .map { group in (user, group) }
                        .catch { error in
                            return Observable.error(RepositoryError.noInviteCode)
                        }
                }
            .flatMap { [weak self] user, group -> Observable<(User, GroupFirestore, UserFirestore)> in
                guard let self = self else { return .empty() }
                return self.fetchUserOnce(userId: user.userID)
                    .map { userFirestore in (user, group, userFirestore) }
            }
            .flatMap { [weak self] user, group, userFirestore -> Observable<(User, GroupFirestore, UserFirestore, Int)> in
                guard let self = self else { return .empty() }
                return self.fetchGroupMemberCount(groupId: group.groupId)
                    .map { count in (user, group, userFirestore, count) }
            }
            .flatMap { [weak self] user, group, userFirestore, memberCount -> Observable<InviteFirestore> in
                guard let self = self else { return .empty() }

                // 10명 이상일 시 에러
                guard memberCount <= 10 else {
                    return Observable.error(RepositoryError.groupIsFull)
                }

                let oldGroupId = userFirestore.groupId


                // 유저가 1인 그룹에 속해 있다면 삭제
                // 멤버 카운트 제대로 불러오기
                // 로그인한 유저의 기존 그룹 멤버 수 확인 -> 1명이면 삭제
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
                            toGroupId: group.groupId,
                            userNickname: user.nickname
                        )
                    }
                    .flatMap {
                        self.fetchInvite(inviteCode: inviteCode)
                    }
            }
    }

    /// 초대 코드를 생성하는 코드
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
                //firebase에서 조작해야 될 것 같은데 어떻게 생각하세요? 서버 요청으로 자동 삭제가 가능할까요?
                // batch? firebase 에서 만들어진 시간 조회해서 하루넘어가면 disabled
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

