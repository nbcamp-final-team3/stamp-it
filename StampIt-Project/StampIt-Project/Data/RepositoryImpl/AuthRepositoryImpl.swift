//
//  AuthRepositoryImpl.swift
//  StampIt-Project
//
//  Created by iOS study on 6/10/25.
//

import RxSwift
import Foundation
import FirebaseFirestore
import FirebaseAuth

final class AuthRepository: AuthRepositoryProtocol {
    
    // MARK: - Properties
    private let authManager: AuthManagerProtocol
    private let firestoreManager: FirestoreManagerProtocol
    private let disposeBag = DisposeBag()
    
    //MARK: - Init
    init(authManager: AuthManagerProtocol,
         firestoreManager: FirestoreManagerProtocol) {
        self.authManager = authManager
        self.firestoreManager = firestoreManager
    }
    
    // MARK: - Sign-In
    /// Google 로그인
    func signInWithGoogle() -> Observable<LoginResult> {
        return performSignIn(authMethod: authManager.signInWithGoogle())
    }
    
    /// Apple 로그인
    func signInWithApple() -> Observable<LoginResult> {
        return performSignIn(authMethod: authManager.signInWithApple())
    }
    
    // MARK: - Sign-In Helper Methods (Private)
    /// 공통 로그인 로직 처리
    private func performSignIn(authMethod: Observable<AuthDataResult>) -> Observable<LoginResult> {
        return authMethod
            .flatMap { [weak self] authDataResult -> Observable<LoginResult> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                return self.processAuthResult(authDataResult)
            }
            .catch { [weak self] error in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                let repositoryError = self.mapToRepositoryError(error)
                return Observable.error(repositoryError)
            }
    }
    
    /// AuthDataResult를 LoginResult로 변환
    private func processAuthResult(_ authDataResult: AuthDataResult) -> Observable<LoginResult> {
        let firebaseUser = authDataResult.user
        let authUser = createAuthUser(
            from: firebaseUser,
            isNewUser: authDataResult.additionalUserInfo?.isNewUser ?? false
        )
        
        if authUser.isNewUser {
            // 신규 사용자: AuthUser 정보만 반환 (나머진 UseCase에서 완전한 User 생성)
            return Observable.just(LoginResult(
                authUser: authUser,
                user: nil,
                isNewUser: true,
                needsGroupSetup: true
            ))
        } else {
            // 기존 사용자: Firestore에서 완전한 정보 조회
            return fetchUserWithGroupInfo(userId: authUser.uid)
                .map { completeUser in
                    return LoginResult(
                        authUser: nil,
                        user: completeUser,
                        isNewUser: false,
                        needsGroupSetup: false
                    )
                }
        }
    }
    
    /// Firebase User를 AuthUser로 변환
    private func createAuthUser(from firebaseUser: FirebaseAuth.User, isNewUser: Bool) -> AuthUser {
        return AuthUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName ?? "사용자",
            photoURL: firebaseUser.photoURL?.absoluteString,
            isNewUser: isNewUser
        )
    }
    
    // MARK: - 사용자+그룹 정보 통합 조회
    /// 사용자 ID로 사용자 정보와 그룹 정보를 통합하여 조회
    func fetchUserWithGroupInfo(userId: String) -> Observable<StampIt_Project.User> {
        return firestoreManager.fetchUser(userId: userId)
            .flatMap { [weak self] userFirestore -> Observable<StampIt_Project.User> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                
                return self.firestoreManager.fetchGroup(groupId: userFirestore.groupId)
                    .flatMap { groupFirestore -> Observable<StampIt_Project.User> in
                        self.firestoreManager.fetchMembers(groupId: userFirestore.groupId)
                            .map { _ in
                                return userFirestore.toDomainModel(
                                    groupName: groupFirestore.name,
                                    isLeader: groupFirestore.leaderId == userFirestore.userId
                                )
                            }
                    }
            }
    }
    
    
    // MARK: - 상태 관리
    /// 현재 로그인된 사용자의 정보를 그룹 정보와 함께 조회
    func getCurrentUser() -> Observable<StampIt_Project.User?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }
            if let firebaseUser = self.authManager.getCurrentUser() {
                self.fetchUserWithGroupInfo(userId: firebaseUser.uid)
                    .subscribe(onNext: { user in
                        observer.onNext(user)
                        observer.onCompleted()
                    }, onError: { _ in
                        observer.onNext(nil)
                        observer.onCompleted()
                    })
                    .disposed(by: self.disposeBag)
            } else {
                observer.onNext(nil)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
    
    /// 인증 상태 변화를 실시간으로 관찰하고 사용자 정보를 반환
    func observeAuthState() -> Observable<StampIt_Project.User?> {
        return authManager.observeAuthState()
            .flatMap { [weak self] firebaseUser -> Observable<StampIt_Project.User?> in
                guard let self = self, let user = firebaseUser else {
                    return Observable.just(nil)
                }
                return self.fetchUserWithGroupInfo(userId: user.uid)
                    .map { user -> StampIt_Project.User? in user }
                    .catchAndReturn(nil)
            }
    }
    
    /// 앱 시작 시 사용자 인증 상태와 온보딩 필요 여부를 확인
    func checkLaunchState() -> Observable<LaunchResult> {
        return getCurrentUser()
            .map { user in
                if let user = user {
                    let needsOnboarding = false // TODO: 온보딩 로직 추가
                    return LaunchResult(
                        isAuthenticated: true,
                        user: user,
                        needsOnboarding: needsOnboarding
                    )
                } else {
                    return LaunchResult(
                        isAuthenticated: false,
                        user: nil,
                        needsOnboarding: false
                    )
                }
            }
            .catch { _ in
                return Observable.just(LaunchResult(
                    isAuthenticated: false,
                    user: nil,
                    needsOnboarding: false
                ))
            }
    }
    
    // MARK: - 온보딩
    /// 온보딩 완료 처리 (추후 구현 예정)
    func completeOnboarding() -> Observable<Void> {
        // TODO: 온보딩 완료 처리
        return Observable.just(())
    }
    
    // MARK: - Internal Firestore Operations
    /// Firestore에 사용자 정보 생성 (내부 전용)
    func createUser(_ user: UserFirestore) -> Observable<Void> {
        return firestoreManager.createUser(user)
    }
    
    /// Firestore에 그룹 정보 생성 (내부 전용)
    func createGroup(_ group: GroupFirestore) -> Observable<Void> {
        return firestoreManager.createGroup(group)
    }
    
    /// Firestore에 그룹 멤버 추가 (내부 전용)
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void> {
        return firestoreManager.addMember(groupId: groupId, member: member)
    }
    
    /// 신규 사용자, 그룹, 멤버를 트랜잭션으로 원자적 생성
    func createNewUserWithGroup(
        user: UserFirestore,
        group: GroupFirestore,
        member: MemberFirestore
    ) -> Observable<StampIt_Project.User> {
        return Observable.create { [weak self] observer in
            guard let _ = self else {
                observer.onError(RepositoryError.unknownError)
                return Disposables.create()
            }
            
            let batch = Firestore.firestore().batch()
            
            // 1. 유저
            let userDict: [String: Any] = [
                "userId": user.userId,
                "nickname": user.nickname,
                "profileImage": user.profileImage as Any,
                "groupId": user.groupId,
                "nicknameChangedAt": user.nicknameChangedAt,
                "createdAt": user.createdAt
            ]
            let userRef = Firestore.firestore().collection("users").document(user.documentID)
            batch.setData(userDict, forDocument: userRef)

            // 2. 그룹
            let groupDict: [String: Any] = [
                "groupId": group.groupId,
                "name": group.name,
                "leaderId": group.leaderId,
                "inviteCode": group.inviteCode,
                "nameChangedAt": group.nameChangedAt,
                "createdAt": group.createdAt
            ]
            let groupRef = Firestore.firestore().collection("groups").document(group.documentID)
            batch.setData(groupDict, forDocument: groupRef)

            // 3. 멤버
            let memberDict: [String: Any] = [
                "userId": member.userId,
                "nickname": member.nickname,
                "joinedAt": member.joinedAt,
                "isLeader": member.isLeader
            ]
            let memberRef = Firestore.firestore()
                .collection("groups")
                .document(group.groupId)
                .collection("members")
                .document(member.documentID)
            batch.setData(memberDict, forDocument: memberRef)
            
            // 커밋
            batch.commit { error in
                if let error = error {
                    observer.onError(RepositoryError.dataError("신규 사용자 생성 실패: \(error.localizedDescription)"))
                } else {
                    let completeUser = user.toDomainModel(
                        groupName: group.name,
                        isLeader: true
                    )
                    observer.onNext(completeUser)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    
    // MARK: - Private Methods
    /// 다양한 에러 타입을 RepositoryError로 매핑
    private func mapToRepositoryError(_ error: Error) -> RepositoryError {
        if let authError = error as? AuthError {
            switch authError {
            case .googleSignInFailed:
                return .authenticationFailed("Google 로그인에 실패했습니다")
            case .firebaseSignInFailed:
                return .authenticationFailed("Firebase 로그인에 실패했습니다")
            case .userNotFound:
                return .userNotFound
            case .presentingViewControllerNotFound:
                return .uiError("화면을 찾을 수 없습니다")
            default:
                return .authenticationFailed(authError.localizedDescription)
            }
        } else if let firestoreError = error as? FirestoreError {
            switch firestoreError {
            case .documentNotFound:
                return .userNotFound
            case .fetchFailed(let message), .createFailed(let message), .updateFailed(let message):
                return .dataError(message)
            default:
                return .dataError(firestoreError.localizedDescription)
            }
        } else {
            return .unknownError
        }
    }
}

// MARK: - Extension 특정 정보만 반환

extension AuthRepository {
    /// 현재 사용자의 그룹 ID 반환
    func getCurrentGroupID() -> Observable<String> {
        return getCurrentUser()
            .compactMap { $0?.groupID }
            .ifEmpty(switchTo: Observable.error(RepositoryError.userNotInGroup))
    }
    
    /// 현재 사용자의 ID 반환
    func getCurrentUserID() -> Observable<String> {
        return getCurrentUser()
            .compactMap { $0?.userID }
            .ifEmpty(switchTo: Observable.error(RepositoryError.userNotFound))
    }
    
    /// 현재 사용자가 리더인지 확인
    func isCurrentUserLeader() -> Observable<Bool> {
        return getCurrentUser()
            .map { $0?.isLeader ?? false }
    }
}
