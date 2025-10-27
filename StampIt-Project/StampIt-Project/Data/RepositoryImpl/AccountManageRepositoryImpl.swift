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
}
