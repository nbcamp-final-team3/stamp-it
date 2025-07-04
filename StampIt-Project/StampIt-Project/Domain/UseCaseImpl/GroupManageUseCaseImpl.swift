//
//  GroupManageUseCaseImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/26/25.
//

import Foundation
import RxSwift

// MARK: - GroupManageUseCase Implementation
final class GroupManageUseCaseImpl: GroupManageUseCase {

    // MARK: - Properties
    private let authRepository: AuthRepositoryProtocol
    private let groupManageRepository: GroupManageRepository
    private let accountManageRepository: AccountManageRepositoryProtocol
    private let inviteRepository: InviteRepository
    private let disposeBag = DisposeBag()

    // MARK: - Init
    init(
        authRepository: AuthRepositoryProtocol,
        groupManageRepository: GroupManageRepository,
        accountManageRepository: AccountManageRepositoryProtocol,
        inviteRepository: InviteRepository
    ) {
        self.authRepository = authRepository
        self.groupManageRepository = groupManageRepository
        self.accountManageRepository = accountManageRepository
        self.inviteRepository = inviteRepository
    }
    
    /// 리더 위임
    func delegateLeader(to memberId: String) -> Observable<Void> {
        return getCurrentUser()
            .flatMap { [weak self] optionalUser -> Observable<Void> in
                guard let self = self, let user = optionalUser else {
                    return Observable.error(GroupUseCaseError.userNotFound)
                }

                // 현재 사용자가 리더인지 확인
                guard user.isLeader else {
                    return Observable.error(GroupUseCaseError.notAuthorized)
                }

                return self.groupManageRepository.delegateLeader(to: memberId, groupId: user.groupID)
            }
            .catch { [weak self] error in
                let groupUseCaseError = self?.mapToGroupUseCaseError(error) ?? GroupUseCaseError.unknownError
                return Observable.error(groupUseCaseError)
            }
    }

    /// 멤버 내보내기
    func exportMember(member: User) -> Observable<User> {
        return getCurrentUser()
            .flatMap { [weak self] optionalUser -> Observable<User> in
                guard let self = self, let currentUser = optionalUser else {
                    return Observable.error(GroupUseCaseError.userNotFound)
                }

                // 현재 사용자가 리더인지 확인
                guard currentUser.isLeader else {
                    return Observable.error(GroupUseCaseError.notAuthorized)
                }

                return self.accountManageRepository.exportMember(member: member)
            }
            .catch { [weak self] error in
                let groupUseCaseError = self?.mapToGroupUseCaseError(error) ?? GroupUseCaseError.unknownError
                return Observable.error(groupUseCaseError)
            }
    }

    /// 현재 사용자 정보 가져오기
    func getCurrentUser() -> Observable<User?> {
        authRepository.getCurrentUser()
    }

    /// 그룹 멤버 목록 가져오기
    func fetchGroupMembers(groupId: String) -> Observable<[Member]> {
        return groupManageRepository.fetchGroupMembers(groupId: groupId)
            .catch { [weak self] error in
                let groupUseCaseError = self?.mapToGroupUseCaseError(error) ?? GroupUseCaseError.unknownError
                return Observable.error(groupUseCaseError)
            }
    }

    /// 그룹 간 이동 (현재 그룹 탈퇴 후 새 그룹 가입)
    func switchToNewGroup(inviteCode: String) -> Observable<Void> {
        return getCurrentUser()
            .flatMap { [weak self] optionalUser -> Observable<Void> in
                guard let self = self, let user = optionalUser else {
                    return Observable.error(GroupUseCaseError.userNotFound)
                }

                // 1. 초대 코드로 새 그룹 정보 조회
                return self.inviteRepository.fetchGroupByInviteCode(inviteCode: inviteCode)
                    .flatMap { [weak self] newGroup -> Observable<Void> in
                        guard let self = self else { return .empty() }

                        // 2. 현재 그룹 탈퇴
                        return self.accountManageRepository.leaveGroup()
                            .flatMap { [weak self] _ -> Observable<Void> in
                                guard let self = self else { return .empty() }

                                // 3. 새 그룹에 멤버로 추가
                                let member = Member(
                                    userID: user.userID,
                                    nickname: user.nickname,
                                    profileImage: user.profileImage,
                                    monthSticker: 0,
                                    joinedAt: Date(),
                                    isLeader: false
                                )

                                return self.inviteRepository.addMember(groupId: newGroup.groupID, member: member)
                            }
                    }
            }
            .catch { [weak self] error in
                let groupUseCaseError = self?.mapToGroupUseCaseError(error) ?? GroupUseCaseError.unknownError
                return Observable.error(groupUseCaseError)
            }
    }

    // MARK: - Group Member Management Methods

    /// 그룹 멤버 관리 초기 데이터 로드
    func loadGroupMemberManageData() -> Observable<GroupMemberLoadModel> {
        return getCurrentUser()
            .flatMap { [weak self] optionalUser -> Observable<GroupMemberLoadModel> in
                guard let self = self, let user = optionalUser else {
                    return Observable.error(GroupUseCaseError.userNotFound)
                }

                return self.groupManageRepository.fetchMembersByGroup(groupId: user.groupID)
                    .map { members in
                        GroupMemberLoadModel(
                            currentUser: user,
                            members: members,
                            isLeader: user.isLeader
                        )
                    }
            }
            .catch { [weak self] error in
                let groupUseCaseError = self?.mapToGroupUseCaseError(error) ?? GroupUseCaseError.unknownError
                return Observable.error(groupUseCaseError)
            }
    }

    /// 멤버 ID로 멤버 내보내기
    func exportMember(memberId: String) -> Observable<Void> {
        return getCurrentUser()
            .flatMap { [weak self] optionalUser -> Observable<User> in
                guard let self = self, let currentUser = optionalUser else {
                    return Observable.error(GroupUseCaseError.userNotFound)
                }

                return self.groupManageRepository.fetchMember(groupId: currentUser.groupID, userId: memberId)
                    .flatMap { member -> Observable<User> in
                        guard let targetMember = member else {
                            return Observable.error(GroupUseCaseError.userNotFound)
                        }

                        let targetUser = targetMember.toUser(
                            groupId: currentUser.groupID,
                            groupName: currentUser.groupName
                        )

                        return Observable.just(targetUser)
                    }
            }
            .flatMap { [weak self] targetUser -> Observable<User> in
                guard let self = self else { return .empty() }
                return self.exportMember(member: targetUser)
            }
            .map { _ in () }
            .catch { [weak self] error in
                let groupUseCaseError = self?.mapToGroupUseCaseError(error) ?? GroupUseCaseError.unknownError
                return Observable.error(groupUseCaseError)
            }
    }

    /// 멤버 목록 새로고침
    func refreshMembers() -> Observable<[Member]> {
        return getCurrentUser()
            .flatMap { [weak self] optionalUser -> Observable<[Member]> in
                guard let self = self, let user = optionalUser else {
                    return Observable.error(GroupUseCaseError.userNotFound)
                }

                return self.groupManageRepository.fetchMembersByGroup(groupId: user.groupID)
            }
            .catch { [weak self] error in
                let groupUseCaseError = self?.mapToGroupUseCaseError(error) ?? GroupUseCaseError.unknownError
                return Observable.error(groupUseCaseError)
            }
    }

    // MARK: - Private Methods

    /// Repository 에러를 GroupUseCaseError로 매핑
    private func mapToGroupUseCaseError(_ error: Error) -> GroupUseCaseError {
        // GroupUseCaseError 처리
        if let groupUseCaseError = error as? GroupUseCaseError {
            return groupUseCaseError
        }

        // RepositoryError 처리
        if let repositoryError = error as? RepositoryError {
            return GroupUseCaseError.fromRepositoryError(repositoryError)
        }

        // Manager 에러들 처리 (UserError, GroupError, MembershipError 등)
        return GroupUseCaseError.fromManagerError(error)
    }
}
