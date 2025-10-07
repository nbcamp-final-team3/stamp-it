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

    private let disposeBag = DisposeBag()

    init(groupManager: any GroupManagerProtocol, userManager: any UserManagerProtocol, membershipManager: any MembershipManagerProtocol, missionManager: any MissionManagerProtocol, stampManager: any StampManagerProtocol) {
        self.groupManager = groupManager
        self.userManager = userManager
        self.membershipManager = membershipManager
        self.missionManager = missionManager
        self.stampManager = stampManager
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
    
    // MARK: -- 주형 멤버 관리 유저 내보내기 기능 구현부
    func exportMember(member: User) -> Observable<User> {
        return self.validateGroupLeaving(currentUser: member)
            .flatMap { _ in
                return self.executeGroupLeaving(currentUser: member)
            }
            .catch { error in
                return Observable.error(error)
            }
    }

    // MARK: - 그룹 탈퇴 전용 검증 (서비스 탈퇴와 분리)
    private func validateGroupLeaving(currentUser: User) -> Observable<Void> {
        let membershipId = "\(currentUser.groupID)_\(currentUser.userID)"
        return membershipManager.fetch(id: membershipId)
            .flatMap { [weak self] membershipOptional -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }

                guard membershipOptional != nil else {
                    return Observable.error(RepositoryError.dataError("멤버십 정보를 찾을 수 없습니다"))
                }

                return self.membershipManager.fetchList(query: .byGroup(currentUser.groupID))
                    .map { memberships in memberships.count }
                    .flatMap { memberCount -> Observable<Void> in
                        // 핵심: 1인 그룹은 그룹 탈퇴 차단
                        if memberCount <= 1 {
                            return Observable.error(
                                RepositoryError.dataError("계정 삭제를 원하신다면\n'서비스 탈퇴'를 이용해주세요.")
                            )
                        } else {
                            // 다인 그룹은 그룹 탈퇴 허용 (리더든 일반 멤버든)
                            return Observable.just(())
                        }
                    }
            }
    }

    // MARK: - 그룹 탈퇴 실행 (서비스 탈퇴와 분리)
    private func executeGroupLeaving(currentUser: User) -> Observable<User> {
        // VM에서 이미 리더 차단했으므로 여기는 일반 멤버
        return leaveGroupAndCreateNew(
            userId: currentUser.userID,
            currentGroupId: currentUser.groupID,
            userNickname: currentUser.nickname,
            profileImageURL: currentUser.profileImage ?? "profileImage1"
        )
    }

    /// 그룹 탈퇴 + 새 1인 그룹 생성 (트랜잭션) (새로운 DB 구조 반영)
    private func leaveGroupAndCreateNew(
        userId: String,
        currentGroupId: String,
        userNickname: String,
        profileImageURL: String?
    ) -> Observable<User> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(RepositoryError.unknownError)
                return Disposables.create()
            }

            let newGroupId = UUID().uuidString
            let now = Date()
            let inviteCode = self.generateInviteCode()

            // 1. 메인 트랜잭션 실행
            self.executeMainTransaction(
                userId: userId,
                currentGroupId: currentGroupId,
                newGroupId: newGroupId,
                userNickname: userNickname,
                inviteCode: inviteCode,
                now: now,
                profileImageURL: profileImageURL ?? "profileImage1"
            )
            .flatMap { _ -> Observable<User> in
                // 2. 데이터 정리 (재시도 로직 포함)
                return self.cleanupUserDataWithRetry(
                    userId: userId,
                    currentGroupId: currentGroupId,
                    maxRetries: 3
                )
                .map { _ in
                    return User(
                        userID: userId,
                        nickname: userNickname,
                        profileImage: profileImageURL ?? "profileImage1",
                        boards: [],
                        groupID: newGroupId,
                        groupName: "\(userNickname)의 그룹",
                        isLeader: true,
                        joinedGroupAt: now
                    )
                }
                .catch { cleanupError in
                    // 3. 데이터 정리 실패 시에도 성공으로 처리 (그룹 탈퇴는 이미 완료됨)
                    return Observable.just(User(
                        userID: userId,
                        nickname: userNickname,
                        profileImage: profileImageURL ?? "profileImage1",
                        boards: [],
                        groupID: newGroupId,
                        groupName: "\(userNickname)의 그룹",
                        isLeader: true,
                        joinedGroupAt: now
                    ))
                }
            }
            .catch { error in
                // 4. 메인 트랜잭션 실패 시 롤백 시도 (결과 처리)
                return self.attemptRollback(
                    userId: userId,
                    currentGroupId: currentGroupId,
                    newGroupId: newGroupId
                )
                .flatMap { _ -> Observable<User> in
                    // 롤백 성공 시에도 원래 에러 반환
                    return Observable.error(self.mapGroupExitError(error))
                }
                .catch { rollbackError in
                    // 롤백도 실패한 경우 더 심각한 에러 반환
                    return Observable.error(self.mapGroupExitError(rollbackError))
                }
            }
            .subscribe(
                onNext: { user in
                    observer.onNext(user)
                    observer.onCompleted()
                },
                onError: { error in
                    observer.onError(error)
                }
            )
            .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    /// 메인 트랜잭션 실행 (배치 작업) (새로운 DB 구조 반영)
    private func executeMainTransaction(
        userId: String,
        currentGroupId: String,
        newGroupId: String,
        userNickname: String,
        inviteCode: String,
        now: Date,
        profileImageURL: String
    ) -> Observable<Void> {
        return Observable.create { observer in
            let batch = Firestore.firestore().batch()

            // 1. 기존 멤버십 제거 (membership 컬렉션 사용)
            let oldMembershipId = "\(currentGroupId)_\(userId)"
            let oldMembershipRef = Firestore.firestore().collection("memberships").document(oldMembershipId)
            batch.deleteDocument(oldMembershipRef)

            // 2. 새 그룹 생성 (leaderId 필드 추가, inviteCode 필드 추가)
            let newGroupRef = Firestore.firestore().collection("groups").document(newGroupId)
            let groupDict: [String: Any] = [
                "groupId": newGroupId,
                "name": "\(userNickname)의 그룹",
                "leaderId": userId, // 새로 추가된 필드
                "inviteCode": inviteCode, // invite 컬렉션 삭제, group 필드로 통일
                "nameChangedAt": Timestamp(date: now),
                "createdAt": Timestamp(date: now)
            ]
            batch.setData(groupDict, forDocument: newGroupRef)

            // 3. 새 멤버십 추가 (membership 컬렉션 사용)
            let newMembershipId = "\(newGroupId)_\(userId)"
            let newMembershipRef = Firestore.firestore().collection("memberships").document(newMembershipId)
            let membershipDict: [String: Any] = [
                "membershipId": newMembershipId,
                "groupId": newGroupId,
                "userId": userId,
                "nickname": userNickname,
                "profileImage": profileImageURL,
                "isLeader": true,
                "joinedAt": Timestamp(date: now)
            ]
            batch.setData(membershipDict, forDocument: newMembershipRef)

            // 4. 사용자 그룹 ID 업데이트
            let userRef = Firestore.firestore().collection("users").document(userId)
            batch.updateData(["groupId": newGroupId], forDocument: userRef)

            // 배치 커밋 (타임아웃 설정)
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                observer.onError(GroupExitError.networkTimeout)
            }

            batch.commit { error in
                timeoutTimer.invalidate()

                if let error = error {
                    let nsError = error as NSError

                    // 세밀한 에러 분류
                    switch nsError.code {
                    case 7: // PERMISSION_DENIED (권한 없음)
                        observer.onError(GroupExitError.insufficientPermissions)
                    case 10: // ABORTED (트랜잭션 충돌)
                        observer.onError(GroupExitError.transactionConflict)
                    case 14: // UNAVAILABLE (네트워크 문제)
                        observer.onError(GroupExitError.networkTimeout)
                    default:
                        observer.onError(GroupExitError.batchCommitFailed(error.localizedDescription))
                    }
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                timeoutTimer.invalidate()
            }
        }
    }

    /// 사용자 데이터 정리_탈퇴하는 그룹의 미션 (재시도 로직 포함) (새로운 매니저 구조 반영)
    private func cleanupUserDataWithRetry(
        userId: String,
        currentGroupId: String,
        maxRetries: Int
    ) -> Observable<Void> {
        return stampManager.deleteUserStamps(userId: userId, groupId: currentGroupId)
            .retry(maxRetries)
            .flatMap { _ in
                return self.missionManager.deleteReceivedMissions(userId: userId, groupId: currentGroupId)
                    .retry(maxRetries)
            }
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .catch { error in
                return Observable.error(GroupExitError.dataCleanupFailed(error.localizedDescription))
            }
    }

    /// 롤백 시도 (베스트 에포트) (새로운 DB 구조 반영)
    private func attemptRollback(
        userId: String,
        currentGroupId: String,
        newGroupId: String
    ) -> Observable<Void> {
        return Observable.create { observer in
            let rollbackBatch = Firestore.firestore().batch()

            // 생성된 새 그룹 삭제 시도
            let newGroupRef = Firestore.firestore().collection("groups").document(newGroupId)
            rollbackBatch.deleteDocument(newGroupRef)

            // 새 멤버십 삭제 시도 (membership 컬렉션 사용)
            let newMembershipId = "\(newGroupId)_\(userId)"
            let newMembershipRef = Firestore.firestore().collection("memberships").document(newMembershipId)
            rollbackBatch.deleteDocument(newMembershipRef)

            // 롤백 배치 커밋 (타임아웃 포함)
            let rollbackTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                observer.onError(GroupExitError.rollbackFailed("롤백 시간 초과"))
            }

            rollbackBatch.commit { error in
                rollbackTimer.invalidate()

                if let error = error {
                    observer.onError(GroupExitError.rollbackFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                rollbackTimer.invalidate()
            }
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

    /// 초대 코드 생성 헬퍼
    private func generateInviteCode() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String(uuid.prefix(8)).uppercased()
    }
}


//    // MARK: - 그룹 탈퇴 전용 검증 (서비스 탈퇴와 분리)
//    private func validateGroupLeaving(currentUser: User) -> Observable<Void> {
//        let membershipId = "\(currentUser.groupID)_\(currentUser.userID)"
//        return membershipManager.fetch(id: membershipId)
//            .flatMap { membershipOptional -> Observable<Void> in
//                guard membershipOptional != nil else {
//                    return Observable.error(RepositoryError.dataError("멤버십 정보를 찾을 수 없습니다"))
//                }
//
//                return self.membershipManager.fetchList(query: .byGroup(currentUser.groupID))
//                    .map { memberships in memberships.count }
//                    .flatMap { memberCount -> Observable<Void> in
//                        if memberCount <= 1 {
//                            return Observable.error(
//                                RepositoryError.dataError("계정 삭제를 원하신다면\n'서비스 탈퇴'를 이용해주세요.")
//                            )
//                        } else {
//                            return Observable.just(())
//                        }
//                    }
//            }
//    }
//
//    // MARK: - 그룹 탈퇴 실행 (서비스 탈퇴와 분리)
//    private func executeGroupLeaving(currentUser: User) -> Observable<User> {
//        return leaveGroupAndCreateNew(
//            userId: currentUser.userID,
//            currentGroupId: currentUser.groupID,
//            userNickname: currentUser.nickname,
//            profileImageURL: currentUser.profileImage ?? "profileImage1"
//        )
//    }
//
//    /// 그룹 탈퇴 + 새 1인 그룹 생성 (트랜잭션)
//    private func leaveGroupAndCreateNew(
//        userId: String,
//        currentGroupId: String,
//        userNickname: String,
//        profileImageURL: String?
//    ) -> Observable<User> {
//        return Observable.create { [weak self] observer in
//            guard let self = self else {
//                observer.onError(RepositoryError.unknownError)
//                return Disposables.create()
//            }
//
//            let newGroupId = UUID().uuidString
//            let now = Date()
//            let inviteCode = self.generateInviteCode()
//
//            let disposable = self.executeMainTransaction(
//                userId: userId,
//                currentGroupId: currentGroupId,
//                newGroupId: newGroupId,
//                userNickname: userNickname,
//                inviteCode: inviteCode,
//                now: now,
//                profileImageURL: profileImageURL ?? "profileImage1"
//            )
//            .flatMap { _ -> Observable<User> in
//                self.cleanupUserDataWithRetry(
//                    userId: userId,
//                    currentGroupId: currentGroupId,
//                    maxRetries: 3
//                )
//                .map { _ in
//                    User(
//                        userID: userId,
//                        nickname: userNickname,
//                        profileImage: profileImageURL ?? "profileImage1",
//                        boards: [],
//                        groupID: newGroupId,
//                        groupName: "\(userNickname)의 그룹",
//                        isLeader: true,
//                        joinedGroupAt: now
//                    )
//                }
//                .catch { _ in
//                    Observable.just(User(
//                        userID: userId,
//                        nickname: userNickname,
//                        profileImage: profileImageURL ?? "profileImage1",
//                        boards: [],
//                        groupID: newGroupId,
//                        groupName: "\(userNickname)의 그룹",
//                        isLeader: true,
//                        joinedGroupAt: now
//                    ))
//                }
//            }
//            .catch { error in
//                self.attemptRollback(
//                    userId: userId,
//                    currentGroupId: currentGroupId,
//                    newGroupId: newGroupId
//                )
//                .flatMap { _ in Observable<User>.error(self.mapGroupExitError(error)) }
//                .catch { rollbackError in Observable<User>.error(self.mapGroupExitError(rollbackError)) }
//            }
//            .subscribe(
//                onNext: { user in
//                    observer.onNext(user)
//                    observer.onCompleted()
//                },
//                onError: { error in
//                    observer.onError(error)
//                }
//            )
//
//            // 핵심: 내부 구독을 반환 Disposables에 넣어서 외부가 해제 가능하게 함
//            return Disposables.create {
//                disposable.dispose()
//            }
//        }
//    }
//
//
//    /// 메인 트랜잭션 실행 (배치 작업)
//    private func executeMainTransaction(
//        userId: String,
//        currentGroupId: String,
//        newGroupId: String,
//        userNickname: String,
//        inviteCode: String,
//        now: Date,
//        profileImageURL: String
//    ) -> Observable<Void> {
//        return Observable.create { observer in
//            let batch = Firestore.firestore().batch()
//
//            let oldMembershipId = "\(currentGroupId)_\(userId)"
//            let oldMembershipRef = Firestore.firestore().collection("memberships").document(oldMembershipId)
//            batch.deleteDocument(oldMembershipRef)
//
//            let newGroupRef = Firestore.firestore().collection("groups").document(newGroupId)
//            let groupDict: [String: Any] = [
//                "groupId": newGroupId,
//                "name": "\(userNickname)의 그룹",
//                "leaderId": userId,
//                "inviteCode": inviteCode,
//                "nameChangedAt": Timestamp(date: now),
//                "createdAt": Timestamp(date: now)
//            ]
//            batch.setData(groupDict, forDocument: newGroupRef)
//
//            let newMembershipId = "\(newGroupId)_\(userId)"
//            let newMembershipRef = Firestore.firestore().collection("memberships").document(newMembershipId)
//            let membershipDict: [String: Any] = [
//                "membershipId": newMembershipId,
//                "groupId": newGroupId,
//                "userId": userId,
//                "nickname": userNickname,
//                "profileImage": profileImageURL,
//                "isLeader": true,
//                "joinedAt": Timestamp(date: now)
//            ]
//            batch.setData(membershipDict, forDocument: newMembershipRef)
//
//            let userRef = Firestore.firestore().collection("users").document(userId)
//            batch.updateData(["groupId": newGroupId], forDocument: userRef)
//
//            batch.commit { error in
//                if let error = error {
//                    let nsError = error as NSError
//                    switch nsError.code {
//                    case 7:
//                        observer.onError(RepositoryError.permissionDenied("권한 부족"))
//                    case 10:
//                        observer.onError(RepositoryError.dataError("동시 작업 충돌"))
//                    case 14:
//                        observer.onError(RepositoryError.networkError("네트워크 시간 초과"))
//                    default:
//                        observer.onError(RepositoryError.dataError("그룹 탈퇴 실패: \(error.localizedDescription)"))
//                    }
//                } else {
//                    observer.onNext(())
//                    observer.onCompleted()
//                }
//            }
//
//            return Disposables.create()
//        }
//    }
//
//    private func generateInviteCode() -> String {
//        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
//        return String(uuid.prefix(8)).uppercased()
//    }
//} 
