//
//  GroupManageRepositoryImpl.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/26/25.
//

import Foundation
import RxSwift
import FirebaseFirestore

final class GroupManageRepositoryImpl: GroupManageRepository {

    private let groupManager: any GroupManagerProtocol
    private let userManager: any UserManagerProtocol
    private let membershipManager: any MembershipManagerProtocol
    private let missionManager: any MissionManagerProtocol
    private let stampManager: any StampManagerProtocol
    private let exportLogicService: any ExportLogicServicingProtocol

    private let disposeBag = DisposeBag()

    init(groupManager: any GroupManagerProtocol,
         userManager: any UserManagerProtocol,
         membershipManager: any MembershipManagerProtocol,
         missionManager: any MissionManagerProtocol,
         stampManager: any StampManagerProtocol,
         exportLogicService: any ExportLogicServicingProtocol) {
        self.groupManager = groupManager
        self.userManager = userManager
        self.membershipManager = membershipManager
        self.missionManager = missionManager
        self.stampManager = stampManager
        self.exportLogicService = exportLogicService
    }

    // MARK: - GroupManageRepository

    func delegateLeader(to memberId: String, groupId: String) -> Observable<Void> {
        // 1. 현재 리더를 일반 멤버로 변경
        return fetchGroupLeader(groupId: groupId)
            .flatMap { [weak self] currentLeader -> Observable<Void> in
                guard let self = self, let leader = currentLeader else {
                    return Observable.error(RepositoryError.userNotFound)
                }

                return self.updateMemberRole(groupId: groupId, userId: leader.userID, isLeader: false)
            }
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }

                // 2. 새로운 리더로 지정
                return self.updateMemberRole(groupId: groupId, userId: memberId, isLeader: true)
            }
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }

                // 3. 그룹의 리더 정보 업데이트
                return self.groupManager.updateGroupLeader(groupId: groupId, newLeaderId: memberId)
            }
    }

    /// 특정 그룹의 리더 조회
    func fetchGroupLeader(groupId: String) -> Observable<Member?> {
        return membershipManager.fetchList(query: .leaders())
            .map { memberships in
                let groupLeader = memberships.first { $0.groupId == groupId }
                return groupLeader?.toDomainModel()  // GroupMembershipFirestore → Member 변환
            }
    }

    /// 특정 그룹의 특정 멤버 조회
    func fetchMember(groupId: String, userId: String) -> Observable<Member?> {
        // 주형: 그룹 매니저 체크 - GroupMembershipFirestore 활용
        return membershipManager.fetchList(query: .byGroupIdAndUserId(groupId: groupId, userId: userId))
            .map { memberships in
                return memberships.first?.toDomainModel()  // GroupMembershipFirestore → Member 변환
            }
    }

    /// 그룹의 모든 멤버 조회 (쿼리 기반)
    func fetchMembersByGroup(groupId: String) -> Observable<[Member]> {
        return membershipManager.fetchList(query: .byGroup(groupId))
            .map { memberships in
                return memberships.map { membership in
                    membership.toDomainModel()  // GroupMembershipFirestore → Member 변환
                }
            }
    }

    /// 멤버 정보 업데이트
    func updateMemberRole(groupId: String, userId: String, isLeader: Bool) -> Observable<Void> {
        return membershipManager.fetchList(query: .byGroupIdAndUserId(groupId: groupId, userId: userId))
            .flatMap { [weak self] memberships -> Observable<Void> in
                guard let self = self, let membership = memberships.first else {
                    return Observable.error(RepositoryError.userNotFound)
                }

                return self.membershipManager.updateFields(id: membership.documentID, fields: ["isLeader": isLeader])
            }
    }

    /// 그룹 멤버 목록 가져오기
    func fetchGroupMembers(groupId: String) -> Observable<[Member]> {
        return membershipManager.fetchList(query: .byGroup(groupId))
            .map { memberships in
                return memberships.map { membership in
                    membership.toDomainModel()  // GroupMembershipFirestore → Member 변환
                }
            }
    }

    // MARK: -- 주형 멤버 관리 유저 내보내기 기능
    func exportMember(member: User) -> Observable<User> {
        print("실행 확인")
        return exportLogicService.exportMember(member)
            .catch { [weak self] error in
                guard let self = self else { return .error(RepositoryError.unknownError)}
                return .error(self.mapGroupExitError(error))
            }
    }

    /// 그룹 탈퇴 전용 에러 매핑
    private func mapGroupExitError(_ error: Error) -> RepositoryError {
        if let groupExitError = error as? GroupExitError {
            switch groupExitError {
            case .userNotFound, .groupNotFound:
                return .userNotFound
            case .batchCommitFailed(let message):
                return .dataError("그룹 탈퇴 실패: \(message)")
            case .dataCleanupFailed(let message):
                return .dataError("데이터 정리 실패: \(message)")
            case .rollbackFailed(let message):
                return .dataError("복구 실패: \(message)")
            case .networkTimeout:
                return .networkError("네트워크 시간 초과")
            case .insufficientPermissions:
                return .permissionDenied("권한 부족")
            case .transactionConflict:
                return .dataError("동시 작업 충돌")
            }
        }

        return mapToRepositoryError(error)
    }

}
