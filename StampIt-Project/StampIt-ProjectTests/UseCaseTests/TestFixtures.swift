//
//  TestFixtures.swift
//  StampIt-ProjectTests
//

import Foundation
@testable import StampIt_Project

struct TestFixtures {
    
    // MARK: - User Fixtures
    
    static let newUser = User(
        userID: "new-user-123",
        nickname: "신규 사용자",
        profileImageURL: "https://example.com/new-profile.jpg",
        boards: [],
        groupID: "",                       
        groupName: "",
        isLeader: false,
        joinedGroupAt: Date()
    )
    
    static let existingUser = User(
        userID: "existing-user-456",
        nickname: "기존 사용자",
        profileImageURL: "https://example.com/existing-profile.jpg",
        boards: [],
        groupID: "existing-group-789",
        groupName: "기존 그룹",
        isLeader: true,
        joinedGroupAt: Date()
    )
    
    // MARK: - LoginResult Fixtures
    
    static let newUserLoginResult = LoginResult(
        user: newUser,
        isNewUser: true,
        needsGroupSetup: true
    )
    
    static let existingUserLoginResult = LoginResult(
        user: existingUser,
        isNewUser: false,
        needsGroupSetup: false
    )
    
    // MARK: - LaunchResult Fixtures
    
    static let unauthenticatedWithOnboarding = LaunchResult(
        isAuthenticated: false,
        user: nil,
        needsOnboarding: true
    )
    
    static let authenticatedLaunchResult = LaunchResult(
        isAuthenticated: true,
        user: existingUser,
        needsOnboarding: false
    )
    
    // MARK: - Mock Nickname Provider
    
    static func mockNicknameProvider(userID: String) -> String {
        return "테스트 닉네임-\(userID.suffix(4))"
    }
}
