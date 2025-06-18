//
//  DIContainer.swift
//  StampIt-Project
//
//  Created by iOS study on 6/10/25.
//

// MARK: - 의존성 주입 컨테이너
// TODO: DIContainer 합치기 전에 사용하실 분들은 아래에 추가하시면 되고, 나중에 합칠때 전체 수정될 예정이니 참고 바랍니다.
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
    
    lazy var missionRepository: MissionRepository = {
        return MissionRepositoryImpl(firestoreManager: firestoreManager, authRepository: authRepository)
    }()

    // MARK: - Use Cases (Domain Layer)
    lazy var loginUseCase: LoginUseCaseProtocol = {
        return LoginUseCase(authRepository: authRepository)
    }()

    lazy var homeUseCase: HomeUseCaseProtocol = {
        return HomeUseCase(authRepository: authRepository, homeRepository: homeRepository)
    }()

    lazy var myPageUseCase: MyPageUseCase = {
        return MyPageUseCaseImpl(
            authRepository: authRepository,
            mypageRepository: myPageRepository
        )
    }()

    lazy var myMissionUseCase: MyMissionUseCaseProtocol = {
        return MyMissionUseCaseImpl(homeRepository: homeRepository)
    }()

    lazy var memberMissionUseCase: MemberMissionUseCaseProtocol = {
        return MemberMissionUseCaseImpl(homeRepository: homeRepository)
    }()

    lazy var missionUseCase: MissionUseCase = {
        return MissionUseCaseImpl(missionRepositoryImpl: missionRepository)
    }()

    // MARK: - ViewModels (Domain Layer)
    func makeLoginViewModel() -> LoginViewModel {
        return LoginViewModel(loginUseCase: loginUseCase)
    }

    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(useCase: homeUseCase)
    }

    func makeMyPageViewModel() -> MyPageViewModel {
        return MyPageViewModel(myPageUseCase: myPageUseCase)
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        return OnboardingViewModel(totalPages: 3)
    }

    func makeMyMissionViewModel(user: User, memberCache: [String: User]) -> MyMissionViewModel {
        return MyMissionViewModel(user: user, memberCache: memberCache, useCase: myMissionUseCase)
    }

    func makeMemberMissionViewModel(user: User, memberCache: [String: User]) -> MemberMissionViewModel {
        return MemberMissionViewModel(user: user, memberCache: memberCache, useCase: memberMissionUseCase)
    }
    
    func makeMissionListViewModel() -> MissionListViewModel {
        return MissionListViewModel(missionUseCaseImpl: missionUseCase)
    }

    // MARK: - ViewControllers (Presentation Layer)
    func makeLoginViewController() -> LoginViewController {
        let viewModel = makeLoginViewModel()
        return LoginViewController(viewModel: viewModel)
    }

    func makeHomeViewController() -> HomeViewController {
        let viewModel = makeHomeViewModel()
        return HomeViewController(viewModel: viewModel)
    }

    func makeMyPageViewController() -> MyPageViewController {
        let viewModel = makeMyPageViewModel()
        return MyPageViewController(viewModel: viewModel)
    }
    
    func makeOnboardingViewController() -> OnboardingViewController {
        let viewModel = makeOnboardingViewModel()
        return OnboardingViewController(viewModel: viewModel)
    }

    func makeMyMissionViewController(user: User, memberCache: [String: User]) -> MyMissionViewController {
        let viewModel = makeMyMissionViewModel(user: user, memberCache: memberCache)
        return MyMissionViewController(viewModel: viewModel)
    }

    func makeMemberMissionViewController(user: User, memberCache: [String: User]) -> MemberMissionViewController {
        let viewModel = makeMemberMissionViewModel(user: user, memberCache: memberCache)
        return MemberMissionViewController(viewModel: viewModel)
    }
    
    func makeMissionListViewController() -> MissionListViewController {
        let viewModel = makeMissionListViewModel()
        return MissionListViewController(viewModel: viewModel)
    }

    // MARK: - Singleton
    static let shared = DIContainer()
    private init() {}
}
