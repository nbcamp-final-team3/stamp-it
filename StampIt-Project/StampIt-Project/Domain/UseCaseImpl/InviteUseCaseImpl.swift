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
        let membershipFirestore = member.toMembershipFirestoreModel(groupId: groupId)
        return authRepository.addMember(groupId: groupId, member: membershipFirestore)
    }

    // send 관련 메서드
    func fetchGroup(groupId: String) -> Observable<Group> {
        inviteRepository.fetchGroup(groupId: groupId)
    }

    func createInvite(_ invite: Invite) -> Observable<Void> {
        inviteRepository.createInvite(invite)
    }

    func fetchInvite(inviteCode: String) -> Observable<Invite> {
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

    func switchUserGroup(userId: String, fromGroupId: String, toGroupId: String, userNickname: String, profileImage: String) -> Observable<Void> {
        inviteRepository.switchUserGroup(userId: userId, fromGroupId: fromGroupId, toGroupId: toGroupId, userNickname: userNickname, profileImage: profileImage)
    }

    /// 초대코드를 받아서 해당 그룹에 새 멤버를 추가하는 코드
    // TODO: 주형님 이거 로직 너무 길어서 줄였어요..ㅠㅠ 그래도 아직까지 책임이 너무 많아서 단일책임 원칙 깨지는데 주석 확인하시면 리팩토링 좀 해주세요..
    func acceptInvite(inviteCode: String) -> Observable<Invite> {
        return getCurrentUser()
            .flatMap { [weak self] optionalUser -> Observable<(User, Invite)> in
                guard let self = self, let user = optionalUser else {
                    return Observable.error(RepositoryError.userNotFound)
                }
                return self.fetchInvite(inviteCode: inviteCode)
                    .map { invite in
                        if invite.groupId == user.groupID {
                            throw RepositoryError.alreadyInGroup
                        }
                        return (user, invite)
                    }
            }
            .flatMap { [weak self] user, invite -> Observable<(User, Group, Int)> in
                guard let self = self else { return .empty() }
                return self.fetchGroupByInviteCode(inviteCode: inviteCode)
                    .flatMap { group in
                        self.fetchGroupMemberCount(groupId: group.groupID)
                            .map { count in (user, group, count) }
                    }
            }
            .flatMap { [weak self] user, group, memberCount -> Observable<(User, Group, Int, Int)> in
                guard let self = self else { return .empty() }
                return self.fetchGroupMemberCount(groupId: user.groupID)
                    .map { oldGroupMemberCount in
                        (user, group, memberCount, oldGroupMemberCount)
                    }
            }
            .flatMap { [weak self] user, group, newGroupMemberCount, oldGroupMemberCount -> Observable<Invite> in
                guard let self = self else { return .empty() }
                guard newGroupMemberCount < 10 else {
                    return .error(RepositoryError.groupIsFull)
                }
                let oldGroupId = user.groupID
                let newGroupId = group.groupID

                let deleteOldGroupObservable: Observable<Void>
                if oldGroupMemberCount == 1 {
                    deleteOldGroupObservable = self.deleteGroup(groupId: oldGroupId)
                } else {
                    deleteOldGroupObservable = .just(())
                }

                return deleteOldGroupObservable
                    .flatMap {
                        self.switchUserGroup(
                            userId: user.userID,
                            fromGroupId: oldGroupId,
                            toGroupId: newGroupId,
                            userNickname: user.nickname,
                            profileImage: user.profileImage ?? "profileImage1"
                        )
                    }
                // TODO: 사용자 데이터 정리: 다인 그룹에서 탈퇴하는 경우
                // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
                // 🔧 필요시 주석 해제하여 활성화
//                    .flatMap { [weak self] _ -> Observable<Void> in
//                        guard let self = self else { return .empty() }
//                        if oldGroupMemberCount > 1 {
//                            return self.inviteRepository.cleanupUserDataWithRetry(
//                                userId: user.userID,
//                                groupId: oldGroupId,
//                                maxRetries: 3
//                            )
//                        } else {
//                            return .just(())
//                        }
//                    }
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
