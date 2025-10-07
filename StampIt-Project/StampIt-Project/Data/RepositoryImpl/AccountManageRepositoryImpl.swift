//
//  AccountManageRepositoryImpl.swift
//  StampIt-Project
//
//  Created by iOS study on 6/24/25.
//

import Foundation
import RxSwift
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn

final class AccountManageRepository: AccountManageRepositoryProtocol {

    private let authManager: any AuthManagerProtocol
    private let userManager: any UserManagerProtocol
    private let groupManager: any GroupManagerProtocol
    private let membershipManager: any MembershipManagerProtocol
    private let missionManager: any MissionManagerProtocol
    private let stampManager: any StampManagerProtocol

    private let authRepository: AuthRepositoryProtocol

    private let disposeBag = DisposeBag()
    private let mapToRepositoryError: (Error) -> RepositoryError

    // 의존성 주입
    init(
        authManager: any AuthManagerProtocol,
        userManager: any UserManagerProtocol,
        groupManager: any GroupManagerProtocol,
        membershipManager: any MembershipManagerProtocol,
        missionManager: any MissionManagerProtocol,
        stampManager: any StampManagerProtocol,
        authRepository: any AuthRepositoryProtocol,
        mapToRepositoryError: @escaping (Error) -> RepositoryError
    ) {
        self.authManager = authManager
        self.userManager = userManager
        self.groupManager = groupManager
        self.membershipManager = membershipManager
        self.missionManager = missionManager
        self.stampManager = stampManager
        self.authRepository = authRepository
        self.mapToRepositoryError = mapToRepositoryError
    }

    // MARK: - 계정 조회
    // 현재 사용자 정보 조회
    private func getCurrentUser() -> Observable<User> {
        return authRepository.getCurrentUser()
            .compactMap { $0 }
            .ifEmpty(switchTo: Observable.error(RepositoryError.userNotFound))
    }

    // MARK: - 로그아웃
    /// 현재 사용자 로그아웃
    func signOut() -> Observable<Void> {
        return authManager.signOut()
            .catch { error in
                Observable.error(self.mapToRepositoryError(error))
            }
    }

    // MARK: - 서비스 탈퇴 (그룹 탈퇴와 완전 분리)
    /// providerID 체크
    private func getCurrentProviderID() -> String? {
        return authManager.getCurrentUser()?.providerData.first?.providerID
    }

    func deleteAccount() -> Observable<Void> {
        print("🔥 [DEBUG] 서비스 탈퇴 시작")
        return getCurrentUser()
            .flatMap { [weak self] user -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                return self.validateAccountDeletion(user: user)
                    .flatMap { _ -> Observable<Void> in
                        let providerID = self.getCurrentProviderID()
                        print("🔍 [DEBUG] Provider: \(providerID ?? "Unknown")")
                        // 애플/구글 모두 동일하게 처리
                        return self.deleteFirestoreDataForAccountDeletion(user: user)
                            .flatMap { _ in
                                self.deleteAuthAccountWithRetryAndReauth(maxRetry: 5)
                            }
                    }
            }
            .do(
                onNext: { _ in print("✅ [DEBUG] 서비스 탈퇴 완료") },
                onError: { error in print("❌ [DEBUG] 서비스 탈퇴 실패: \(error)") }
            )
    }
    
    // MARK: - 재인증 메서드(서비스 탈퇴)
    private func reauthenticateUser() -> Observable<Void> {
        guard let user = Auth.auth().currentUser else {
            return Observable.error(RepositoryError.userNotFound)
        }
        
        // 현재 사용자의 로그인 제공자 확인
        guard let providerData = user.providerData.first else {
            return Observable.error(RepositoryError.authenticationFailed("로그인 제공자를 찾을 수 없습니다"))
        }
        
        let providerId = providerData.providerID
        
        print("[DEBUG] 재인증 시작 - Provider: \(providerId)")
        
        switch providerId {
        case "google.com":
            return reauthenticateWithGoogle(user: user)
        case "apple.com":
            return reauthenticateWithApple(user: user)
        default:
            return Observable.error(RepositoryError.authenticationFailed("지원하지 않는 로그인 방식: \(providerId)"))
        }
    }
    
    // MARK: - Google 재인증
    private func reauthenticateWithGoogle(user: FirebaseAuth.User) -> Observable<Void> {
        return authManager.signInWithGoogle()
            .flatMap { _ -> Observable<Void> in
                // Google 로그인 성공 후 credential 생성
                guard let googleUser = GIDSignIn.sharedInstance.currentUser,
                      let idToken = googleUser.idToken?.tokenString else {
                    return Observable.error(RepositoryError.authenticationFailed("Google 토큰을 가져올 수 없습니다"))
                }
                
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: googleUser.accessToken.tokenString
                )
                
                return Observable.create { observer in
                    user.reauthenticate(with: credential) { _, error in
                        if let error = error {
                            print("[DEBUG] Google 재인증 실패: \(error.localizedDescription)")
                            observer.onError(RepositoryError.authenticationFailed("Google 재인증 실패"))
                        } else {
                            print("[DEBUG] Google 재인증 성공")
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                    return Disposables.create()
                }
            }
    }

    // MARK: - Apple 재인증
    private func reauthenticateWithApple(user: FirebaseAuth.User) -> Observable<Void> {
        return authManager.signInWithApple()
            .flatMap { authResult -> Observable<Void> in
                // Apple 로그인에서 받은 credential 사용
                guard let appleCredential = authResult.credential else {
                    return Observable.error(RepositoryError.authenticationFailed("Apple credential을 가져올 수 없습니다"))
                }
                
                return Observable.create { observer in
                    user.reauthenticate(with: appleCredential) { _, error in
                        if let error = error {
                            print("[DEBUG] Apple 재인증 실패: \(error.localizedDescription)")
                            observer.onError(RepositoryError.authenticationFailed("Apple 재인증 실패"))
                        } else {
                            print("[DEBUG] Apple 재인증 성공")
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                    return Disposables.create()
                }
            }
    }


    // MARK: - 서비스 탈퇴 전용 검증 (그룹 탈퇴와 완전 분리)
    private func validateAccountDeletion(user: User) -> Observable<Void> {
        let membershipId = "\(user.groupID)_\(user.userID)"

        return membershipManager.fetch(id: membershipId)
            .flatMap { [weak self] membershipOptional -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }

                guard let membership = membershipOptional else {
                    return Observable.just(())
                }

                if membership.isLeader {
                    return self.membershipManager.fetchList(query: .byGroup(user.groupID))
                        .map { memberships in memberships.count }
                        .flatMap { memberCount -> Observable<Void> in
                            if memberCount > 1 {
                                return Observable.error(
                                    RepositoryError.dataError("다른 멤버에게 리더 위임 후\n서비스 탈퇴가 가능합니다.")
                                )
                            } else {
                                return Observable.just(())
                            }
                        }
                } else {
                    return Observable.just(())
                }
            }
    }

    // MARK: - 서비스 탈퇴 전용 Firestore 데이터 삭제 (그룹 탈퇴와 완전 분리)
    private func deleteFirestoreDataForAccountDeletion(user: User) -> Observable<Void> {
        print("🔥 [DEBUG] Firestore 데이터 삭제 시작")

        let userId = user.userID
        let groupId = user.groupID
        let isLeader = user.isLeader

        if isLeader {
            return membershipManager.fetchList(query: .byGroup(groupId))
                .map { memberships in memberships.count }
                .flatMap { [weak self] memberCount -> Observable<Void> in
                    guard let self = self else {
                        return Observable.error(RepositoryError.unknownError)
                    }

                    if memberCount == 1 {
                        return self.deleteSingleUserGroupForAccountDeletion(userId: userId, groupId: groupId)
                    } else {
                        return Observable.error(RepositoryError.dataError("다른 멤버에게 리더 위임 후\n서비스 탈퇴가 가능합니다."))
                    }
                }
        } else {
            return deleteRegularMemberForAccountDeletion(userId: userId, groupId: groupId)
        }
    }


    // MARK: - 서비스 탈퇴용 1인 그룹 삭제 (그룹 탈퇴와 분리)
    private func deleteSingleUserGroupForAccountDeletion(userId: String, groupId: String) -> Observable<Void> {
        print("🔍 [DEBUG] 1인 그룹 삭제")

        return Observable.zip(
            groupManager.delete(id: groupId),
            userManager.delete(id: userId),
            stampManager.deleteUserStamps(userId: userId),
            missionManager.deleteGroupMissions(groupId: groupId),
            membershipManager.deleteGroupMemberships(groupId: groupId)
        )
        .map { _ in () }
        .catch { error in
            return Observable.error(RepositoryError.dataError("계정 삭제 실패: \(error.localizedDescription)"))
        }
    }

    // MARK: - 서비스 탈퇴용 일반 멤버 삭제 (그룹 탈퇴와 분리)
    private func deleteRegularMemberForAccountDeletion(userId: String, groupId: String) -> Observable<Void> {
        print("🔍 [DEBUG] 일반 멤버 삭제")

        return Observable.zip(
            membershipManager.removeMember(groupId: groupId, userId: userId),
            userManager.delete(id: userId),
            stampManager.deleteUserStamps(userId: userId),
            missionManager.deleteReceivedMissions(userId: userId, groupId: groupId)
        )
        .map { _ in () }
        .catch { error in
            return Observable.error(RepositoryError.dataError("계정 삭제 실패: \(error.localizedDescription)"))
        }
    }

    // MARK: - Firebase Auth 계정 삭제 (재시도 + 재인증)
    private func deleteAuthAccountWithRetryAndReauth(maxRetry: Int) -> Observable<Void> {
        var retryCount = 0
        
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(RepositoryError.unknownError)
                return Disposables.create()
            }
            
            func attemptDelete() {
                print("🔄 [DEBUG] 계정 삭제 시도 \(retryCount + 1)/\(maxRetry)")
                
                self.authManager.deleteAccountWithSocialRevoke()
                    .subscribe(
                        onNext: {
                            print("✅ [DEBUG] Firebase Auth 삭제 성공")
                            observer.onNext(())
                            observer.onCompleted()
                        },
                        onError: { error in
                            retryCount += 1
                            let nsError = error as NSError
                            
                            // Firebase Auth 에러 코드 17014: requires-recent-login
                            if nsError.code == 17014 {
                                print("🔄 [DEBUG] 재인증 필요 - 재인증 시도")
                                self.handleReauthenticationAndDelete(observer: observer)
                            } else if retryCount >= maxRetry {
                                print("❌ [DEBUG] 최대 재시도 횟수 초과")
                                observer.onError(RepositoryError.authenticationFailed("계정 삭제 실패: 최대 재시도 초과"))
                            } else {
                                print("🔄 [DEBUG] \(retryCount)/\(maxRetry) 재시도 중...")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    attemptDelete()
                                }
                            }
                        }
                    )
                    .disposed(by: self.disposeBag)
            }
            
            attemptDelete()
            return Disposables.create()
        }
    }

    // MARK: - 재인증 후 계정 삭제 처리
    private func handleReauthenticationAndDelete(observer: AnyObserver<Void>) {
        self.reauthenticateUser()
            .flatMap { _ -> Observable<Void> in
                print("✅ [DEBUG] 재인증 완료 - 계정 삭제 재시도")
                return self.authManager.deleteAccountWithSocialRevoke()
            }
            .subscribe(
                onNext: {
                    print("✅ [DEBUG] 재인증 후 계정 삭제 성공")
                    observer.onNext(())
                    observer.onCompleted()
                },
                onError: { error in
                    print("❌ [DEBUG] 재인증 후에도 계정 삭제 실패: \(error)")
                    observer.onError(RepositoryError.authenticationFailed("재인증 후에도 계정 삭제 실패"))
                }
            )
            .disposed(by: self.disposeBag)
    }



    // MARK: - 그룹 탈퇴 (서비스 탈퇴와 완전 분리)
    /// 그룹 멤버 수 조회
    func getGroupMemberCount(groupId: String) -> Observable<Int> {
        return membershipManager.fetchList(query: .byGroup(groupId))
            .map { memberships in memberships.count }
            .catch { [weak self] error in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                return Observable.error(self.mapToRepositoryError(error))
            }
    }

    /// 그룹 탈퇴 후 새로운 1인 그룹 생성 - 서비스 탈퇴와 완전 독립적
    func leaveGroup() -> Observable<User> {
        return getCurrentUser()
            .flatMap { [weak self] currentUser -> Observable<User> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }

                // 그룹 탈퇴 전용 검증
                return self.validateGroupLeaving(currentUser: currentUser)
                    .flatMap { _ in
                        // 그룹 탈퇴 실행
                        return self.executeGroupLeaving(currentUser: currentUser)
                    }
            }
            .catch { [weak self] error in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                return Observable.error(self.mapToRepositoryError(error))
            }
    }

//    // MARK: -- 주형 멤버 관리 유저 내보내기 기능 구현부
//    func exportMember(member: User) -> Observable<User> {
//        // 💡 그룹 탈퇴 전용 검증
//        return self.validateGroupLeaving(currentUser: member)
//            .flatMap { _ in
//                // 💡 그룹 탈퇴 실행
//                return self.executeGroupLeaving(currentUser: member)
//            }
//            .catch { [weak self] error in
//                guard let self = self else {
//                    return Observable.error(RepositoryError.unknownError)
//                }
//                return Observable.error(self.mapToRepositoryError(error))
//            }
//    }

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
