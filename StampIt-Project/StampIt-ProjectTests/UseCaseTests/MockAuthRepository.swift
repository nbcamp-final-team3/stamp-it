//
//  MockAuthRepository.swift
//  StampIt-ProjectTests
//

import Foundation
import RxSwift
@testable import StampIt_Project

final class MockAuthRepository: AuthRepositoryProtocol {
    
    // MARK: - Test Control Properties
    var shouldFailSignIn = false
    var shouldFailCreateUser = false
    var mockLoginResult: LoginResult?
    var mockLaunchResult: LaunchResult?
    var mockUser: User?
    var signInCallCount = 0
    var createUserCallCount = 0
    
    // MARK: - Mock Data Storage
    var createdUsers: [UserFirestore] = []
    var createdGroups: [GroupFirestore] = []
    var createdMembers: [MemberFirestore] = []
    
    // MARK: - AuthRepositoryProtocol Implementation
    
    func signInWithGoogle() -> Observable<LoginResult> {
        signInCallCount += 1
        
        if shouldFailSignIn {
            return Observable.error(RepositoryError.authenticationFailed("Mock Google 로그인 실패"))
        }
        
        return Observable.just(mockLoginResult ?? createDefaultLoginResult())
    }
    
    func signInWithApple() -> Observable<LoginResult> {
        signInCallCount += 1
        
        if shouldFailSignIn {
            return Observable.error(RepositoryError.authenticationFailed("Mock Apple 로그인 실패"))
        }
        
        return Observable.just(mockLoginResult ?? createDefaultLoginResult())
    }
    
    func fetchUserWithGroupInfo(userId: String) -> Observable<User> {
        if let mockUser = mockUser {
            return Observable.just(mockUser)
        }
        return Observable.just(createDefaultUser())
    }
    
    func getCurrentUser() -> Observable<User?> {
        return Observable.just(mockUser)
    }
    
    func observeAuthState() -> Observable<User?> {
        return Observable.just(mockUser)
    }
    
    func checkLaunchState() -> Observable<LaunchResult> {
        return Observable.just(mockLaunchResult ?? createDefaultLaunchResult())
    }
    
    func completeOnboarding() -> Observable<Void> {
        return Observable.just(())
    }
    
    func createUser(_ user: UserFirestore) -> Observable<Void> {
        createUserCallCount += 1
        createdUsers.append(user)
        return Observable.just(())
    }
    
    func createGroup(_ group: GroupFirestore) -> Observable<Void> {
        createdGroups.append(group)
        return Observable.just(())
    }
    
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void> {
        createdMembers.append(member)
        return Observable.just(())
    }
    
    func createNewUserWithGroup(
        user: UserFirestore,
        group: GroupFirestore,
        member: MemberFirestore
    ) -> Observable<User> {
        createUserCallCount += 1
        
        if shouldFailCreateUser {
            return Observable.error(RepositoryError.dataError("Mock 사용자 생성 실패"))
        }
        
        // Mock 데이터 저장
        createdUsers.append(user)
        createdGroups.append(group)
        createdMembers.append(member)
        
        // ✅ 올바른 User 생성 (모든 필수 파라미터 포함)
        let completeUser = User(
            userID: user.userId,
            nickname: user.nickname,
            profileImageURL: user.profileImage,
            boards: [],                   
            groupID: user.groupId,
            groupName: group.name,
            isLeader: member.isLeader,
            joinedGroupAt: Date()
        )
        
        return Observable.just(completeUser)
    }
    
    // MARK: - Helper Methods
    
    private func createDefaultLoginResult() -> LoginResult {
        return LoginResult(
            user: createDefaultUser(),
            isNewUser: true,
            needsGroupSetup: true
        )
    }
    
    private func createDefaultUser() -> User {
        return User(
            userID: "test-user-id",
            nickname: "테스트 사용자",
            profileImageURL: "https://example.com/profile.jpg",
            boards: [],
            groupID: "test-group-id",
            groupName: "테스트 그룹",
            isLeader: false,
            joinedGroupAt: Date()
        )
    }
    
    private func createDefaultLaunchResult() -> LaunchResult {
        return LaunchResult(
            isAuthenticated: false,
            user: nil,
            needsOnboarding: true
        )
    }
    
    // MARK: - Test Helper Methods
    
    func reset() {
        shouldFailSignIn = false
        shouldFailCreateUser = false
        mockLoginResult = nil
        mockLaunchResult = nil
        mockUser = nil
        signInCallCount = 0
        createUserCallCount = 0
        createdUsers.removeAll()
        createdGroups.removeAll()
        createdMembers.removeAll()
    }
}
