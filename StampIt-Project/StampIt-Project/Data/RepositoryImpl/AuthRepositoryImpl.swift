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
import KakaoSDKUser

final class AuthRepository: AuthRepositoryProtocol {
    
    // MARK: - Properties
    // 각 매니저별로 분리된 의존성 (새로운 매니저 구조)
    private let kakaoAuthManager: any KakaoAuthManagerProtocol
    private let authManager: any AuthManagerProtocol
    private let userManager: any UserManagerProtocol
    private let groupManager: any GroupManagerProtocol
    private let membershipManager: any MembershipManagerProtocol
    private let missionManager: any MissionManagerProtocol
    private let stampManager: any StampManagerProtocol
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(
        kakaoAuthManager: any KakaoAuthManagerProtocol,
        authManager: any AuthManagerProtocol,
        userManager: any UserManagerProtocol,
        groupManager: any GroupManagerProtocol,
        membershipManager: any MembershipManagerProtocol,
        missionManager: any MissionManagerProtocol,
        stampManager: any StampManagerProtocol
    ) {
        self.kakaoAuthManager = kakaoAuthManager
        self.authManager = authManager
        self.userManager = userManager
        self.groupManager = groupManager
        self.membershipManager = membershipManager
        self.missionManager = missionManager
        self.stampManager = stampManager
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
    
    // Kakao 로그인
    func signInWithKakao() -> Observable<LoginResult> {
        return kakaoAuthManager.signInWithKakao()
            .flatMap { result -> Observable<LoginResult> in
                let userId = result.userId
                
                // Firestore에서 유저 존재 여부 확인
                return self.userManager.fetchUser(userId: userId)
                    .flatMap { userFirestore -> Observable<LoginResult> in
                        // 기존 유저
                        return self.fetchUserWithGroupInfo(userId: userId)
                            .map { completeUser in
                                return LoginResult(authUser: nil, user: completeUser, isNewUser: false, needsGroupSetup: false)
                            }
                            .catch { error in
                                
                                // 사용자는 존재하지만 그룹 정보 로드 실패 시
                                // 새 그룹 생성 없이 기본 정보로 로그인 처리
                                let user = User(
                                    userID: userId,
                                    nickname: userFirestore.nickname,
                                    profileImage: userFirestore.profileImage ?? "profileImage1",
                                    boards: [],
                                    groupID: userFirestore.groupId,
                                    groupName: "내 그룹", // 임시 그룹명
                                    isLeader: true, // 기본적으로 리더로 가정
                                    joinedGroupAt: userFirestore.createdAt.dateValue()
                                )
                                
                                return Observable.just(LoginResult(
                                    authUser: nil,
                                    user: user,
                                    isNewUser: false,
                                    needsGroupSetup: false
                                ))
                            }
                    }
                    .catch { error in
                        // 유저 없으면 신규 유저 플로우
                        let authUser = AuthUser(
                            uid: userId,
                            email: "",
                            displayName: result.nickname ?? "사용자",
                            photoURL: nil,
                            isNewUser: true
                        )
                        return Observable.just(LoginResult(authUser: authUser, user: nil, isNewUser: true, needsGroupSetup: true))
                    }
            }
    }

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
                guard self != nil else {
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
                            .catch { error in
                                // 멤버십 정보가 없어도 기본 사용자 정보는 반환
                                let isLeader = groupFirestore.leaderId == userFirestore.userId
                                let user = userFirestore.toDomainModel(
                                    groupName: groupFirestore.name,
                                    isLeader: isLeader
                                )
                                return Observable.just(user)
                            }
                    }
                    .catch { error in
                        return Observable.error(RepositoryError.dataError("그룹 정보를 불러올 수 없습니다: \(error.localizedDescription)"))
                    }
            }
    }
    
    // MARK: - 상태 관리
    /// 현재 로그인된 사용자의 정보를 그룹 정보와 함께 조회 (카카오는 세션으로 확인 후 조회)
    func getCurrentUser() -> Observable<User?> {
        return Observable.create { observer in
            // 1. Firebase 인증 확인
            if let firebaseUser = Auth.auth().currentUser {
                self.fetchUserWithGroupInfo(userId: firebaseUser.uid)
                    .subscribe(onNext: { user in
                        observer.onNext(user)
                        observer.onCompleted()
                    }, onError: { _ in
                        observer.onNext(nil)
                        observer.onCompleted()
                    })
                    .disposed(by: self.disposeBag)
            }
            // 2. 카카오 로그인 세션 확인 (UserDefaults에서 kakaoUserId가 있으면 그걸로 user fetch)
            else if let kakaoUserId = UserDefaults.standard.string(forKey: "kakaoUserId") {
                self.fetchUserWithGroupInfo(userId: kakaoUserId)
                    .subscribe(onNext: { user in
                        observer.onNext(user)
                        observer.onCompleted()
                    }, onError: { _ in
                        observer.onNext(nil)
                        observer.onCompleted()
                    })
                    .disposed(by: self.disposeBag)
            }
            else {
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
    
    func addMember(groupId: String, member: GroupMembershipFirestore) -> Observable<Void> {
        return membershipManager.create(member)
    }
    
    /// 신규 사용자, 그룹, 멤버를 트랜잭션으로 원자적 생성 (새로운 DB 구조 반영)
    func createNewUserWithGroup(
        user: User,
        group: Group,
        member: Member
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
                groupName: "\(user.nickname)의 그룹",
                inviteCode: group.inviteCode,
            )
            //let memberFirestore = member.toFirestoreModel()
            let memberFirestore = member.toMembershipFirestoreModel(groupId: group.groupID)
            
            // 1. 유저 생성 (FCM 토큰은 별도로 저장)
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
            
            // 2. 그룹 생성
            let groupDict: [String: Any] = [
                "groupId": groupFirestore.groupId,
                "name": groupFirestore.name,
                "leaderId": groupFirestore.leaderId,
                "inviteCode": groupFirestore.inviteCode,
                "inviteCodeCreateAt": groupFirestore.inviteCodeCreateAt ?? Timestamp(date: Date()),
                "nameChangedAt": groupFirestore.nameChangedAt,
                "createdAt": groupFirestore.createdAt
            ]
            let groupRef = Firestore.firestore().collection("groups").document(groupFirestore.documentID)
            batch.setData(groupDict, forDocument: groupRef)
            
            // 3. 멤버십 생성
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
            
            // 4. 커밋
            batch.commit { error in
                if let error = error {
                    observer.onError(RepositoryError.dataError("신규 사용자 생성 실패: \(error.localizedDescription)"))
                } else {
                    // 성공 후 즉시 사용자 정보 다시 로드하여 검증
                    self.fetchUserWithGroupInfo(userId: user.userID)
                        .subscribe(
                            onNext: { completeUser in
                                observer.onNext(completeUser)
                                observer.onCompleted()
                            },
                            onError: { error in
                                // 생성은 성공했으므로 원본 사용자 객체 반환
                                observer.onNext(user)
                                observer.onCompleted()
                            }
                        )
                        .disposed(by: self.disposeBag)
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
