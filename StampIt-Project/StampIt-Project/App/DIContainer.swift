//
//  DIContainer.swift
//  StampIt-Project
//
//  Created by iOS study on 6/10/25.
//

import UIKit
import Foundation

// MARK: - 의존성 주입 컨테이너
final class DIContainer {

    // MARK: - Managers (Infrastructure Layer)
    lazy var authManager: AuthManagerProtocol = {
        return AuthManager()
    }()

    lazy var firestoreManager: FirestoreManagerProtocol = {
        return FirestoreManager()
    }()

    // MARK: - Repositories (Data Layer)
    lazy var authRepository: AuthRepositoryProtocol = {
        return AuthRepository(
            authManager: authManager,
            firestoreManager: firestoreManager
        )
    }()

    lazy var homeRepository: HomeRepositoryProtocol = {
        return HomeRepository(manager: firestoreManager)
    }()

    lazy var myPageRepository: MyPageRepository = {
        return MyPageRepositoryImpl(firestoreManager: firestoreManager)
    }()

    lazy var inviteRepository: InviteRepository = {
        return InviteRepositoryImpl(firestoreManager: firestoreManager)
    }()
    
    lazy var missionRepository: MissionRepository = {
        return MissionRepositoryImpl(firestoreManager: firestoreManager, authRepository: authRepository)
    }()
    
    lazy var editProfileRepository: EditProfileRepository = {
        return EditProfileRepositoryImpl(firestoreManager: firestoreManager)
    }()

    // MARK: - Services

    lazy var missionExpirationService: MissionExpirationService = {
        return MissionExpirationServiceImpl(homeRepository: homeRepository)
    }()

    // MARK: - Use Cases (Domain Layer)
    lazy var loginUseCase: LoginUseCaseProtocol = {
        return LoginUseCase(authRepository: authRepository)
    }()

    lazy var rankingUseCase: RankingUseCaseProtocol = {
        return RankingUseCase(authRepository: authRepository, homeRepository: homeRepository)
    }()

    lazy var myPageUseCase: MyPageUseCase = {
        return MyPageUseCaseImpl(
            authRepository: authRepository,
            mypageRepository: myPageRepository
        )
    }()

    lazy var myMissionUseCase: MyMissionUseCaseProtocol = {
        return MyMissionUseCaseImpl(
            homeRepository: homeRepository,
            expirationService: missionExpirationService
        )
    }()

    lazy var memberMissionUseCase: MemberMissionUseCaseProtocol = {
        return MemberMissionUseCaseImpl(
            homeRepository: homeRepository,
            expirationService: missionExpirationService
        )
    }()

    lazy var missionUseCase: MissionUseCase = {
        return MissionUseCaseImpl(missionRepositoryImpl: missionRepository)
    }()

    lazy var inviteUseCase: InviteUseCase = {
        return InviteUseCaseImpl(
            authRepository: authRepository,
            inviteRepository: inviteRepository
        )
    }()

    lazy var accountManageUseCase: AccountManageUseCaseProtocol = {
        return AccountManageUseCase(authRepository: authRepository)
    }()
    
    lazy var editProfileUseCase: EditProfileUseCase = {
        return EditProfileUseCaseImpl(editProfileRepositoryImpl: editProfileRepository)
    }()
    
    // MARK: - ViewModels (Domain Layer)
    func makeLoginViewModel() -> LoginViewModel {
        return LoginViewModel(loginUseCase: loginUseCase)
    }

    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(
            rankingUseCase: rankingUseCase,
            myMissionUseCase: myMissionUseCase,
            memberMissionUseCase: memberMissionUseCase,
            memberMapper: MemberMapper(),
            missionMapper: MissionMapper(),
        )
    }

    func makeMyPageViewModel() -> MyPageViewModel {
        return MyPageViewModel(
            myPageUseCase: myPageUseCase,
            accountManageUseCase: accountManageUseCase
        )
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        return OnboardingViewModel(totalPages: 3)
    }

    func makeMyMissionViewModel(user: User, memberCache: [String: Member]) -> MyMissionViewModel {
        return MyMissionViewModel(user: user, memberCache: memberCache, useCase: myMissionUseCase)
    }

    func makeMemberMissionViewModel(user: User, memberCache: [String: Member]) -> MemberMissionViewModel {
        return MemberMissionViewModel(user: user, memberCache: memberCache, useCase: memberMissionUseCase)
    }
    
    func makeMissionListViewModel() -> MissionListViewModel {
        return MissionListViewModel(missionUseCaseImpl: missionUseCase)
    }

    func makeReceiveInviteViewModel() -> ReceiveInviteViewModel {
        return ReceiveInviteViewModel(useCase: inviteUseCase)
    }

    func makeSendInviteViewModel() -> SendInviteViewModel {
        return SendInviteViewModel(useCase: inviteUseCase)
    }
    
    func makeEditProfileViewModel(user: User) -> EditProfileViewModel {
        return EditProfileViewModel(user: user, editProfileUseCaseImpl: editProfileUseCase)
    }

    // MARK: - ViewControllers (Presentation Layer)
    func makeLoginViewController() -> LoginViewController {
        let viewModel = makeLoginViewModel()
        return LoginViewController(viewModel: viewModel, container: self)
    }

    func makeHomeViewController() -> HomeViewController {
        let viewModel = makeHomeViewModel()
        return HomeViewController(viewModel: viewModel)
    }

    func makeMyPageViewController() -> MyPageViewController {
        let viewModel = makeMyPageViewModel()
        return MyPageViewController(viewModel: viewModel, container: self)
    }
    
    func makeOnboardingViewController() -> OnboardingViewController {
        let viewModel = makeOnboardingViewModel()
        return OnboardingViewController(viewModel: viewModel)
    }

    func makeMyMissionViewController(user: User, memberCache: [String: Member]) -> MyMissionViewController {
        let viewModel = makeMyMissionViewModel(user: user, memberCache: memberCache)
        return MyMissionViewController(viewModel: viewModel)
    }

    func makeMemberMissionViewController(user: User, memberCache: [String: Member]) -> MemberMissionViewController {
        let viewModel = makeMemberMissionViewModel(user: user, memberCache: memberCache)
        return MemberMissionViewController(viewModel: viewModel)
    }
    
    func makeMissionListViewController() -> MissionListViewController {
        let viewModel = makeMissionListViewModel()
        return MissionListViewController(viewModel: viewModel)
    }

    func makeReceiveInviteViewController() -> ReceiveInviteViewController {
        let viewModel = makeReceiveInviteViewModel()
        return ReceiveInviteViewController(viewModel: viewModel)
    }

    func makeSendInviteViewController() -> SendInviteViewController {
        let viewModel = makeSendInviteViewModel()
        return SendInviteViewController(viewModel: viewModel)
    }

    func makeEditProfileViewController(user: User) -> EditProfileViewController {
        let viewModel = makeEditProfileViewModel(user: user)
        return EditProfileViewController(viewModel: viewModel)
    }
    
    // MARK: - Singleton
    static let shared = DIContainer()
    private init() {}
}
