//
//  exportLogicService.swift
//  StampIt-Project
//
//  Created by 윤주형 on 10/7/25.
//

import RxSwift
import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class ExportLogicService: ExportLogicServiceProtocols {

    private let membershipManager: any MembershipManagerProtocol
    private let stampManager: any StampManagerProtocol
    private let missionManager: any MissionManagerProtocol

    private let disposeBag = DisposeBag()

    init(
        membershipManager: any MembershipManagerProtocol,
        stampManager: any StampManagerProtocol,
        missionManager: any MissionManagerProtocol,
    ) {
        self.stampManager = stampManager
        self.membershipManager = membershipManager
        self.missionManager = missionManager
    }

    // MARK: -- 주형 멤버 관리 유저 내보내기 기능 구현부
    func exportMember(_ member: User) -> Observable<User> {
        return self.validateGroupLeaving(currentUser: member)
            .flatMap { [weak self] _ -> Observable<User> in
                guard let self = self else { return .error(RepositoryError.unknownError) }
                return self.executeGroupLeaving(currentUser: member)
            }
    }

    // MARK: - 그룹 탈퇴 전용 검증 (서비스 탈퇴와 분리)
    internal func validateGroupLeaving(currentUser: User) -> Observable<Void> {
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
                .flatMap { _ in Observable<User>.error(error) } // 원본 에러 그대로 올림
                .catch { rollbackError in Observable<User>.error(rollbackError) }
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

    /// 초대 코드 생성 헬퍼
    private func generateInviteCode() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String(uuid.prefix(8)).uppercased()
    }
}
