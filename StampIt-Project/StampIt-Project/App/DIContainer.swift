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

    private lazy var myPageRepository: MyPageRepository = {
        return MyPageRepositoryImpl(firestoreManager: firestoreManager)
    }()

    // MARK: - Use Cases (Domain Layer)
    lazy var loginUseCase: LoginUseCaseProtocol = {
        return LoginUseCase(authRepository: authRepository)
    }()

    lazy var homeUseCase: HomeUseCaseProtocol = {
        return HomeUseCase(authRepository: authRepository, homeRepository: homeRepository)
    }()

    private lazy var myPageUseCase: MyPageUseCase = {
        return MyPageUseCaseImpl(
            authRepository: authRepository,
            mypageRepository: myPageRepository
        )
    }()
    
    // MARK: - ViewModels (Domain Layer)
    func makeLoginViewModel() -> LoginViewModel {
        return LoginViewModel(loginUseCase: loginUseCase)
    }

    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(useCase: homeUseCase)
    }

    private func makeMyPageViewModel() -> MyPageViewModel {
        return MyPageViewModel(myPageUseCase: myPageUseCase)
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

    // MARK: - Singleton
    static let shared = DIContainer()
    private init() {}
}
