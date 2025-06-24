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
    
    // 각 매니저별로 분리된 의존성 (새로운 매니저 구조)
    private let userManager: UserManager
    private let groupManager: GroupManager
    private let membershipManager: MembershipManager
    private let missionManager: MissionManager
    private let stickerManager: StickerManager
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(
        authManager: AuthManagerProtocol,
        userManager: UserManager,
        groupManager: GroupManager,
        membershipManager: MembershipManager,
        missionManager: MissionManager,
        stickerManager: StickerManager
    ) {
        self.authManager = authManager
        self.userManager = userManager
        self.groupManager = groupManager
        self.membershipManager = membershipManager
        self.missionManager = missionManager
        self.stickerManager = stickerManager
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
                return Observable.error(error)
            }
    }
    
    /// AuthDataResult를 LoginResult로 변환
    private func processAuthResult(_ authDataResult: AuthDataResult) -> Observable<LoginResult> {
        let firebaseUser = authDataResult.user
        let isNewUser = authDataResult.additionalUserInfo?.isNewUser ?? false
        let authUser = createAuthUser(
            from: firebaseUser,
            isNewUser: isNewUser
        )

        if isNewUser {
            // 신규 사용자 플로우
            return Observable.just(LoginResult(
                authUser: authUser,
                user: nil,
                isNewUser: true,
                needsGroupSetup: true
            ))
        } else {
            // 기존 사용자: Firestore에서 정보 조회
            return fetchUserWithGroupInfo(userId: authUser.uid)
                .map { completeUser in
                    return LoginResult(
                        authUser: nil,
                        user: completeUser,
                        isNewUser: false,
                        needsGroupSetup: false
                    )
                }
                .catch { error in
                    // Firestore에 유저 문서가 없으면 신규 유저 플로우로 전환
                    if let userError = error as? UserError,
                       case .userNotFound = userError {
                        return Observable.just(LoginResult(
                            authUser: authUser,
                            user: nil,
                            isNewUser: true,
                            needsGroupSetup: true
                        ))
                    } else {
                        return Observable.error(error)
                    }
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
    
    // MARK: - 사용자+그룹 정보 통합 조회 (새로운 DB 구조 반영)
    /// 사용자 ID로 사용자 정보와 그룹 정보를 통합하여 조회
    func fetchUserWithGroupInfo(userId: String) -> Observable<StampIt_Project.User> {
        return userManager.fetchUser(userId: userId)
            .flatMap { [weak self] userFirestore -> Observable<StampIt_Project.User> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                
                return self.groupManager.fetchGroup(groupId: userFirestore.groupId)
                    .flatMap { groupFirestore -> Observable<StampIt_Project.User> in
                        // membership 컬렉션에서 멤버 정보 조회
                        let membershipId = "\(userFirestore.groupId)_\(userFirestore.userId)"
                        return self.membershipManager.fetch(id: membershipId)
                            .map { membership -> StampIt_Project.User in
                                let isLeader = groupFirestore.leaderId == userFirestore.userId
                                return userFirestore.toDomainModel(
                                    groupName: groupFirestore.name,
                                    isLeader: isLeader
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
    
    // MARK: - Internal Firestore Operations (새로운 매니저 구조 반영)
    /// Firestore에 사용자 정보 생성 (내부 전용)
    func createUser(_ user: UserFirestore) -> Observable<Void> {
        return userManager.create(user)
    }

    func createGroup(_ group: GroupFirestore) -> Observable<Void> {
        return groupManager.create(group)
    }

    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void> {
        // member 컬렉션 삭제, membership 컬렉션 사용
        let membership = GroupMembershipFirestore(
            membershipId: "\(groupId)_\(member.userId)",
            groupId: groupId,
            userId: member.userId,
            nickname: member.nickname,
            profileImage: member.profileImage,
            isLeader: member.isLeader,
            joinedAt: member.joinedAt
        )
        return membershipManager.create(membership)
    }
    
    /// 신규 사용자, 그룹, 멤버를 트랜잭션으로 원자적 생성 (새로운 DB 구조 반영)
    func createNewUserWithGroup(
        user: User,
        group: Group,
        member: Member,
        invite: Invitation
    ) -> Observable<StampIt_Project.User> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(RepositoryError.unknownError)
                return Disposables.create()
            }
            
            let batch = Firestore.firestore().batch()
            
            // Domain → Infrastructure 변환
            let userFirestore = user.toFirestoreModel()
            let groupFirestore = group.toFirestoreModel(
                name: "\(user.nickname)의 그룹",
                inviteCode: invite.inviteCode
            )
            let memberFirestore = member.toFirestoreModel()
            
            // 1. 유저 생성
            let userDict: [String: Any] = [
                "userId": userFirestore.userId,
                "nickname": userFirestore.nickname,
                "groupId": userFirestore.groupId,
                "profileImage": userFirestore.profileImage ?? "profileImage1",
                "nicknameChangedAt": userFirestore.nicknameChangedAt,
                "createdAt": userFirestore.createdAt
            ]
            let userRef = Firestore.firestore().collection("users").document(userFirestore.documentID)
            batch.setData(userDict, forDocument: userRef)
            
            // 2. 그룹 생성 (leaderId 필드 추가)
            let groupDict: [String: Any] = [
                "groupId": groupFirestore.groupId,
                "name": groupFirestore.name,
                "leaderId": groupFirestore.leaderId, // 새로 추가된 필드
                "inviteCode": groupFirestore.inviteCode, // invite 컬렉션 삭제, group 필드로 통일
                "nameChangedAt": groupFirestore.nameChangedAt,
                "createdAt": groupFirestore.createdAt
            ]
            let groupRef = Firestore.firestore().collection("groups").document(groupFirestore.documentID)
            batch.setData(groupDict, forDocument: groupRef)
            
            // 3. 멤버십 생성 (membership 컬렉션 사용)
            let membershipId = "\(groupFirestore.groupId)_\(memberFirestore.userId)"
            let membershipDict: [String: Any] = [
                "membershipId": membershipId,
                "groupId": groupFirestore.groupId,
                "userId": memberFirestore.userId,
                "nickname": memberFirestore.nickname,
                "profileImage": memberFirestore.profileImage ?? "profileImage1",
                "isLeader": memberFirestore.isLeader,
                "joinedAt": memberFirestore.joinedAt
            ]
            let membershipRef = Firestore.firestore().collection("memberships").document(membershipId)
            batch.setData(membershipDict, forDocument: membershipRef)
            
            // 커밋
            batch.commit { error in
                if let error = error {
                    observer.onError(RepositoryError.dataError("신규 사용자 생성 실패: \(error.localizedDescription)"))
                } else {
                    observer.onNext(user)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}

// MARK: - Extension 특정 정보만 반환 (옵셔널 체이닝 사용)
extension AuthRepository {
    /// 현재 사용자의 그룹 ID 반환
    func getCurrentGroupID() -> Observable<String> {
        return getCurrentUser()
            .compactMap { user -> String? in
                return user?.groupID
            }
            .ifEmpty(switchTo: Observable.error(RepositoryError.userNotInGroup))
    }
    
    /// 현재 사용자의 ID 반환
    func getCurrentUserID() -> Observable<String> {
        return getCurrentUser()
            .compactMap { user -> String? in
                return user?.userID
            }
            .ifEmpty(switchTo: Observable.error(RepositoryError.userNotFound))
    }
    
    /// 현재 사용자가 리더인지 확인
    func isCurrentUserLeader() -> Observable<Bool> {
        return getCurrentUser()
            .map { user -> Bool in
                return user?.isLeader ?? false
            }
    }
}
