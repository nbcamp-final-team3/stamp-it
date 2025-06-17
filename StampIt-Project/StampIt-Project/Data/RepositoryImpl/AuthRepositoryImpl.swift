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
        user: User,
        group: Group,
        member: Member,
        invite: Invitation
    ) -> Observable<StampIt_Project.User> {
        return Observable.create { [weak self] observer in
            guard let _ = self else {
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
            let inviteFirestore = invite.toFirestoreModel()
            
            // 1. 유저
            let userDict: [String: Any] = [
                "userId": userFirestore.userId,
                "nickname": userFirestore.nickname,
                "profileImage": userFirestore.profileImage as Any,
                "groupId": userFirestore.groupId,
                "nicknameChangedAt": userFirestore.nicknameChangedAt,
                "createdAt": userFirestore.createdAt
            ]
            let userRef = Firestore.firestore().collection("users").document(userFirestore.documentID)
            batch.setData(userDict, forDocument: userRef)
            
            // 2. 그룹
            let groupDict: [String: Any] = [
                "groupId": groupFirestore.groupId,
                "name": groupFirestore.name,
                "leaderId": groupFirestore.leaderId,
                "inviteCode": groupFirestore.inviteCode,
                "nameChangedAt": groupFirestore.nameChangedAt,
                "createdAt": groupFirestore.createdAt
            ]
            let groupRef = Firestore.firestore().collection("groups").document(groupFirestore.documentID)
            batch.setData(groupDict, forDocument: groupRef)
            
            // 3. 멤버
            let memberDict: [String: Any] = [
                "userId": memberFirestore.userId,
                "nickname": memberFirestore.nickname,
                "joinedAt": memberFirestore.joinedAt,
                "isLeader": memberFirestore.isLeader
            ]
            let memberRef = Firestore.firestore()
                .collection("groups")
                .document(groupFirestore.groupId)
                .collection("members")
                .document(memberFirestore.documentID)
            batch.setData(memberDict, forDocument: memberRef)
            
            // 4. 초대 코드
            let inviteDict: [String: Any] = [
                "inviteCode": inviteFirestore.inviteCode,
                "groupId": inviteFirestore.groupId,
                "createdBy": inviteFirestore.createdBy,
                "createdAt": inviteFirestore.createdAt,
                "expiredAt": inviteFirestore.expiredAt as Any
            ]
            let inviteRef = Firestore.firestore().collection("invites").document(inviteFirestore.documentID)
            batch.setData(inviteDict, forDocument: inviteRef)
            
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

// MARK: - 계정 관리 기능 확장
extension AuthRepository {
    
    // MARK: - 로그아웃
    /// 현재 사용자 로그아웃
    func signOut() -> Observable<Void> {
        return authManager.signOut()
            .catch { [weak self] error in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                return Observable.error(self.mapToRepositoryError(error))
            }
    }
    
    // MARK: - 계정 탈퇴
    /// 계정 탈퇴 (소셜 로그인 연결 해제 + Firestore 데이터 완전 삭제)
    func deleteAccount() -> Observable<Void> {
        return getCurrentUserID()
            .flatMap { [weak self] userId -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                
                // 1. Firestore 데이터 완전 삭제
                return self.deleteAllUserData(userId: userId)
                    .flatMap { _ in
                        // 2. Firebase Auth 계정 삭제 (소셜 연결 해제 포함)
                        return self.authManager.deleteAccountWithSocialRevoke()
                    }
            }
            .catch { [weak self] error in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                return Observable.error(self.mapToRepositoryError(error))
            }
    }
    
    // MARK: - 그룹 탈퇴
    /// 그룹 멤버 수 조회
    func getGroupMemberCount(groupId: String) -> Observable<Int> {
        return firestoreManager.fetchGroupMemberCount(groupId: groupId)
            .catch { [weak self] error in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                return Observable.error(self.mapToRepositoryError(error))
            }
    }
    
    /// 그룹 탈퇴 후 새로운 1인 그룹 생성
    func leaveGroup() -> Observable<User> {
        return getCurrentUser()
            .compactMap { $0 }
            .flatMap { [weak self] currentUser -> Observable<User> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                
                return self.leaveGroupAndCreateNew(
                    userId: currentUser.userID,
                    currentGroupId: currentUser.groupID,
                    userNickname: currentUser.nickname
                )
            }
            .catch { [weak self] error in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                return Observable.error(self.mapToRepositoryError(error))
            }
    }
    
    // MARK: - Private Methods
    
    /// 사용자 관련 모든 Firestore 데이터 삭제 (계정 탈퇴용)
    private func deleteAllUserData(userId: String) -> Observable<Void> {
        return getCurrentUser()
            .compactMap { $0 }
            .flatMap { [weak self] (user: StampIt_Project.User) -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(RepositoryError.unknownError)
                }
                let groupId = user.groupID
                return Observable.zip(
                    self.firestoreManager.deleteUserStickers(userId: userId),
                    self.firestoreManager.deleteUserMissions(userId: userId, groupId: groupId),
                    self.firestoreManager.deleteUserInvites(userId: userId),
                    self.firestoreManager.removeMember(groupId: groupId, userId: userId),
                    self.firestoreManager.deleteUser(userId: userId)
                )
                .map { _ in () }
                .catch { error in
                    return Observable.just(())
                }
            }
    }
    
    /// 그룹 탈퇴 + 새 1인 그룹 생성 (트랜잭션)
    private func leaveGroupAndCreateNew(
        userId: String,
        currentGroupId: String,
        userNickname: String
    ) -> Observable<User> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(RepositoryError.unknownError)
                return Disposables.create()
            }
            
            let newGroupId = UUID().uuidString
            let now = Date()
            let inviteCode = self.generateInviteCode()
            
            let batch = Firestore.firestore().batch()
            
            // 1. 기존 그룹에서 멤버 제거
            let oldMemberRef = Firestore.firestore()
                .collection("groups")
                .document(currentGroupId)
                .collection("members")
                .document(userId)
            batch.deleteDocument(oldMemberRef)
            
            // 2. 새 그룹 생성
            let newGroupRef = Firestore.firestore().collection("groups").document(newGroupId)
            let groupDict: [String: Any] = [
                "groupId": newGroupId,
                "name": "\(userNickname)의 그룹",
                "leaderId": userId,
                "inviteCode": inviteCode,
                "nameChangedAt": Timestamp(date: now),
                "createdAt": Timestamp(date: now)
            ]
            batch.setData(groupDict, forDocument: newGroupRef)
            
            // 3. 새 그룹에 멤버 추가
            let newMemberRef = Firestore.firestore()
                .collection("groups")
                .document(newGroupId)
                .collection("members")
                .document(userId)
            let memberDict: [String: Any] = [
                "userId": userId,
                "nickname": userNickname,
                "joinedAt": Timestamp(date: now),
                "isLeader": true
            ]
            batch.setData(memberDict, forDocument: newMemberRef)
            
            // 4. 사용자 그룹 ID 업데이트
            let userRef = Firestore.firestore().collection("users").document(userId)
            batch.updateData(["groupId": newGroupId], forDocument: userRef)
            
            // 5. 새 초대 코드 생성
            let inviteRef = Firestore.firestore().collection("invites").document(inviteCode)
            let inviteDict: [String: Any] = [
                "inviteCode": inviteCode,
                "groupId": newGroupId,
                "createdBy": userId,
                "createdAt": Timestamp(date: now),
                "expiredAt": NSNull() // 영구 초대 코드
            ]
            batch.setData(inviteDict, forDocument: inviteRef)
            
            // 6. 커밋
            batch.commit { error in
                if let error = error {
                    observer.onError(RepositoryError.dataError("그룹 탈퇴 실패: \(error.localizedDescription)"))
                } else {
                    // 새로 생성된 사용자 정보 반환
                    let newUser = User(
                        userID: userId,
                        nickname: userNickname,
                        profileImageURL: nil,
                        boards: [],
                        groupID: newGroupId,
                        groupName: "\(userNickname)의 그룹",
                        isLeader: true,
                        joinedGroupAt: now
                    )
                    observer.onNext(newUser)
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    /// 초대 코드 생성 헬퍼
    private func generateInviteCode() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String(uuid.prefix(8)).uppercased()
    }
}
