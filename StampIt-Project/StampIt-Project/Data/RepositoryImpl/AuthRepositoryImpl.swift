//
//  AuthRepositoryImpl.swift
//  StampIt-Project
//
//  Created by iOS study on 6/10/25.
//

import RxSwift
import Foundation

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
    
    // MARK: - Google Sign-In
    func signInWithGoogle() -> Observable<LoginResult> {
        return authManager.signInWithGoogle()
            .flatMap { [weak self] authDataResult -> Observable<LoginResult> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                let firebaseUser = authDataResult.user
                let authUser = AuthUser(
                    uid: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    displayName: firebaseUser.displayName ?? "",
                    photoURL: firebaseUser.photoURL?.absoluteString,
                    isNewUser: authDataResult.additionalUserInfo?.isNewUser ?? false
                )
                // 도메인 모델로 변환
                let user = StampIt_Project.User(
                    userID: authUser.uid,
                    nickname: authUser.displayName,
                    profileImageURL: authUser.photoURL,
                    boards: [],
                    groupID: "",
                    groupName: "",
                    isLeader: false,
                    joinedGroupAt: Date()
                )
                return Observable.just(LoginResult(
                    user: user,
                    isNewUser: authUser.isNewUser,
                    needsGroupSetup: authUser.isNewUser
                ))
            }
            .catch { error in
                let repositoryError = self.mapToRepositoryError(error)
                return Observable.error(repositoryError)
            }
    }
    
    // MARK: - Apple Sign-In (준비)
    func signInWithApple() -> Observable<LoginResult> {
        return authManager.signInWithApple()
            .flatMap { [weak self] authDataResult -> Observable<LoginResult> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                let firebaseUser = authDataResult.user
                let authUser = AuthUser(
                    uid: firebaseUser.uid,
                    email: firebaseUser.email ?? "",
                    displayName: firebaseUser.displayName ?? "사용자",
                    photoURL: nil,
                    isNewUser: authDataResult.additionalUserInfo?.isNewUser ?? false
                )
                let user = StampIt_Project.User(
                    userID: authUser.uid,
                    nickname: authUser.displayName,
                    profileImageURL: authUser.photoURL,
                    boards: [],
                    groupID: "", groupName: "",
                    isLeader: false,
                    joinedGroupAt: Date()
                )
                return Observable.just(LoginResult(
                    user: user,
                    isNewUser: authUser.isNewUser,
                    needsGroupSetup: authUser.isNewUser
                ))
            }
            .catch { error in
                let repositoryError = self.mapToRepositoryError(error)
                return Observable.error(repositoryError)
            }
    }
    
    // MARK: - 사용자+그룹 정보 통합 조회
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
    func completeOnboarding() -> Observable<Void> {
        // TODO: 온보딩 완료 처리
        return Observable.just(())
    }
    
    // MARK: - 내부 전용 Firestore CRUD (외부 노출 X)
    func createUser(_ user: UserFirestore) -> Observable<Void> {
        return firestoreManager.createUser(user)
    }
    func createGroup(_ group: GroupFirestore) -> Observable<Void> {
        return firestoreManager.createGroup(group)
    }
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void> {
        return firestoreManager.addMember(groupId: groupId, member: member)
    }
    
    /// 에러 매핑
    private func mapToRepositoryError(_ error: Error) -> RepositoryError {
        if let authError = error as? AuthError {
            switch authError {
            case .googleSignInFailed(let message), .firebaseSignInFailed(let message):
                return .authenticationFailed(message)
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
