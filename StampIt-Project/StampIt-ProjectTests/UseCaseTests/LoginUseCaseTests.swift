//
//  LoginUseCaseTests.swift
//  StampIt-ProjectTests
//

import XCTest
import RxSwift
@testable import StampIt_Project

final class LoginUseCaseTests: XCTestCase {
    
    private var sut: LoginUseCase!
    private var mockRepository: MockAuthRepository!
    private var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAuthRepository()
        disposeBag = DisposeBag()
        
        sut = LoginUseCase(
            authRepository: mockRepository,
            randomNicknameProvider: { userID in "테스트-\(userID.suffix(4))" }
        )
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        disposeBag = nil
        super.tearDown()
    }
    
    // MARK: - 기존 사용자 로그인 테스트
    
    func test_loginWithGoogle_기존유저_성공() {
        // Given
        let expectation = XCTestExpectation(description: "기존 사용자 로그인 성공")
        
        let existingUser = User(
            userID: "existing-user-123",
            nickname: "기존 사용자",
            profileImageURL: "https://example.com/profile.jpg",
            boards: [],                    
            groupID: "existing-group-456",
            groupName: "기존 그룹",
            isLeader: true,
            joinedGroupAt: Date()
        )
        
        mockRepository.mockLoginResult = LoginResult(
            user: existingUser,
            isNewUser: false,
            needsGroupSetup: false
        )
        
        var result: LoginFlowResult?
        
        // When
        sut.loginWithGoogle()
            .subscribe(
                onNext: { flowResult in
                    result = flowResult
                    expectation.fulfill()
                },
                onError: { _ in
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertNotNil(result)
        XCTAssertFalse(result?.isNewUser ?? true)
        XCTAssertEqual(result?.nextAction, .navigateToMain)
        XCTAssertEqual(mockRepository.signInCallCount, 1)
        XCTAssertEqual(mockRepository.createUserCallCount, 0) // 기존 사용자는 생성 안함
    }
    
    // MARK: - 신규 사용자 로그인 테스트
    
    func test_loginWithGoogle_신규유저_자동그룹생성() {
        // Given
        let expectation = XCTestExpectation(description: "신규 사용자 자동 그룹 생성")
        
        let newUser = User(
            userID: "new-user-789",
            nickname: "신규 사용자",
            profileImageURL: nil,
            boards: [],
            groupID: "",
            groupName: "",
            isLeader: false,
            joinedGroupAt: Date()
        )
        
        mockRepository.mockLoginResult = LoginResult(
            user: newUser,
            isNewUser: true,
            needsGroupSetup: true
        )
        
        var result: LoginFlowResult?
        
        // When
        sut.loginWithGoogle()
            .subscribe(
                onNext: { flowResult in
                    result = flowResult
                    expectation.fulfill()
                },
                onError: { _ in
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.isNewUser ?? false)
        XCTAssertEqual(result?.nextAction, .showWelcomeMessage)
        XCTAssertEqual(mockRepository.signInCallCount, 1)
        XCTAssertEqual(mockRepository.createUserCallCount, 1) // 신규 사용자는 그룹 생성
        
        // 생성된 데이터 검증
        XCTAssertEqual(mockRepository.createdUsers.count, 1)
        XCTAssertEqual(mockRepository.createdGroups.count, 1)
        XCTAssertEqual(mockRepository.createdMembers.count, 1)
    }
    
    // MARK: - 로그인 실패 테스트
    
    func test_loginWithGoogle_실패() {
        // Given
        let expectation = XCTestExpectation(description: "로그인 실패")
        mockRepository.shouldFailSignIn = true
        
        var receivedError: Error?
        
        // When
        sut.loginWithGoogle()
            .subscribe(
                onNext: { _ in
                    XCTFail("성공하면 안됨")
                    expectation.fulfill()
                },
                onError: { error in
                    receivedError = error
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertNotNil(receivedError)
    }
    
    // MARK: - 런치 상태 테스트
    
    func test_checkLaunchState_미로그인() {
        // Given
        let expectation = XCTestExpectation(description: "런치 상태 - 미로그인")
        
        mockRepository.mockLaunchResult = LaunchResult(
            isAuthenticated: false,
            user: nil,
            needsOnboarding: true
        )
        
        var result: LaunchFlowResult?
        
        // When
        sut.checkLaunchState()
            .subscribe(
                onNext: { launchResult in
                    result = launchResult
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.nextScreen, .onboarding)
        XCTAssertNil(result?.user)
    }
    
    func test_checkLaunchState_로그인됨() {
        // Given
        let expectation = XCTestExpectation(description: "런치 상태 - 로그인됨")
        
        let loggedInUser = User(
            userID: "logged-user-123",
            nickname: "로그인된 사용자",
            profileImageURL: nil,
            boards: [],
            groupID: "user-group-456",
            groupName: "사용자 그룹",
            isLeader: false,
            joinedGroupAt: Date()
        )
        
        mockRepository.mockLaunchResult = LaunchResult(
            isAuthenticated: true,
            user: loggedInUser,
            needsOnboarding: false
        )
        
        var result: LaunchFlowResult?
        
        // When
        sut.checkLaunchState()
            .subscribe(
                onNext: { launchResult in
                    result = launchResult
                    expectation.fulfill()
                }
            )
            .disposed(by: disposeBag)
        
        // Then
        wait(for: [expectation], timeout: 3.0)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.nextScreen, .main)
        XCTAssertNotNil(result?.user)
        XCTAssertEqual(result?.user?.userID, "logged-user-123")
    }
}
