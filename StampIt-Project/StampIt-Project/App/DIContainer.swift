//
//  DIContainer.swift
//  StampIt-Project
//
//  Created by iOS study on 6/10/25.
//

import UIKit

// MARK: - 의존성 주입 컨테이너
final class DIContainer {

    // MARK: - Managers (Infrastructure Layer)
    lazy var authManager: any AuthManagerProtocol = AuthManager()
    lazy var userManager: any UserManagerProtocol = UserManager()
    lazy var fcmManager: any FCMTokenManagerProtocol = FCMTokenManager()
    lazy var groupManager: any GroupManagerProtocol = GroupManager()
    lazy var membershipManager: any MembershipManagerProtocol = MembershipManager()
    lazy var missionManager: any MissionManagerProtocol = MissionManager()
    lazy var stampManager: any StampManagerProtocol = StampManager()
    lazy var noticeManager: any NoticeManagerProtocol = NoticeManager()

    // MARK: - Coordinators
    lazy var tokenCoordinator: TokenCoordinator = TokenCoordinator(fcmManager: fcmManager)

    // MARK: - Repositories (Data Layer)
    lazy var authRepository: AuthRepositoryProtocol = {
        return AuthRepository(
            authManager: authManager,
            userManager: userManager,
            groupManager: groupManager,
            membershipManager: membershipManager,
            missionManager: missionManager,
            stampManager: stampManager
        )
    }()

    lazy var homeRepository: HomeRepositoryProtocol = {
        return HomeRepository(
            membershipManager: membershipManager,
            stampManager: stampManager,
            missionManager: missionManager
        )
    }()

    lazy var myPageRepository: MyPageRepository = {
        return MyPageRepositoryImpl(
            stampManager: stampManager,
            userManager: userManager
        )
    }()

    lazy var inviteRepository: InviteRepositoryProtocol = {
        return InviteRepositoryImpl(
            groupManager: groupManager,
            membershipManager: membershipManager,
            userManager: userManager,
            // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
             missionManager: missionManager,
             stampManager: stampManager,
             noticeManager: noticeManager
        )
    }()

    lazy var missionRepository: MissionRepository = {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        return MissionRepositoryImpl(
            missionManager: missionManager,
            membershipManager: membershipManager,
            authRepository: authRepository,
            context: context
        )
    }()

    lazy var editProfileRepository: EditProfileRepository = {
        return EditProfileRepositoryImpl(
            userManager: userManager,
            groupManager: groupManager,
            membershipManager: membershipManager
        )
    }()

    lazy var groupManageRepository: GroupManageRepository = {
        return GroupManageRepositoryImpl(
            groupManager: groupManager,
            userManager: userManager,
            membershipManager: membershipManager,
            missionManager: missionManager,
            stampManager: stampManager,
            exportLogicService: exportService
        )
    }()

    lazy var accountManageRepository: AccountManageRepositoryProtocol = {
        return AccountManageRepository(
            authManager: authManager,
            userManager: userManager,
            groupManager: groupManager,
            membershipManager: membershipManager,
            missionManager: missionManager,
            stampManager: stampManager,
            authRepository: authRepository,
            mapToRepositoryError: { error in
                return RepositoryError.unknownError
            }
        )
    }()

    lazy var noticeRepository: NoticeRepositoryProtocol = {
        return NoticeRepository(noticeManager: noticeManager, authManager: authManager)
    }()

    // MARK: - Services

    lazy var missionExpirationService: MissionExpirationService = {
        return MissionExpirationServiceImpl(homeRepository: homeRepository)
    }()

    lazy var exportService: ExportLogicServiceProtocols = {
        return ExportLogicService(membershipManager: membershipManager, stampManager: stampManager, missionManager: missionManager)
    }()

    // MARK: - Use Cases (Domain Layer)
    lazy var loginUseCase: LoginUseCaseProtocol = {
        return LoginUseCase(authRepository: authRepository)
    }()

    lazy var rankingUseCase: RankingUseCaseProtocol = {
        return RankingUseCase(authRepository: authRepository, homeRepository: homeRepository)
    }()

    lazy var myPageUseCase: MyPageUseCaseProtocol = {
        return MyPageUseCaseImpl(
            authRepository: authRepository,
            mypageRepository: myPageRepository
        )
    }()

    lazy var myMissionUseCase: MyMissionUseCaseProtocol = {
        return MyMissionUseCaseImpl(
            homeRepository: homeRepository,
            authRepository: authRepository,
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
        return MissionUseCaseImpl(
            authRepository: authRepository,
            missionRepositoryImpl: missionRepository,
            noticeRepository: noticeRepository
        )
    }()

    lazy var inviteUseCase: InviteUseCase = {
        return InviteUseCaseImpl(
            authRepository: authRepository,
            inviteRepository: inviteRepository
        )
    }()

    lazy var accountManageUseCase: AccountManageUseCaseProtocol = {
        return AccountManageUseCase(
            accountManageRepository: accountManageRepository,
            authRepository: authRepository
        )
    }()
    
    lazy var editProfileUseCase: EditProfileUseCase = {
        return EditProfileUseCaseImpl(editProfileRepositoryImpl: editProfileRepository)
    }()
    
    lazy var groupManageUseCase: GroupManageUseCase = {
        return GroupManageUseCaseImpl(
            authRepository: authRepository,
            groupManageRepository: groupManageRepository,
            accountManageRepository: accountManageRepository, inviteRepository: inviteRepository
        )
    }()

    lazy var noticeUseCase: NoticeUseCaseProtocol = {
        return NoticeUseCase(repository: noticeRepository)
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
    
    func makeStampBoardViewModel() -> StampBoardViewModel {
        return StampBoardViewModel(myPageUseCase: myPageUseCase)
    }
    
    func makeProfileViewModel() -> ProfileViewModel {
        return ProfileViewModel(
            myPageUseCase: myPageUseCase,
            accountManageUseCase: accountManageUseCase
        )
    }
    
    func makeMyPageViewModel() -> MyPageViewModel {
        return MyPageViewModel()
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        return OnboardingViewModel(totalPages: 3)
    }

    func makeMyMissionViewModel() -> MyMissionViewModel {
        return MyMissionViewModel(
            useCase: myMissionUseCase,
            mapper: MissionMapper(),
        )
    }

    func makeMemberMissionViewModel(user: User, memberCache: [String: Member]) -> MemberMissionViewModel {
        return MemberMissionViewModel(
            user: user,
            memberCache: memberCache,
            useCase: memberMissionUseCase,
            memberMapper: MemberMapper(),
            missionMapper: MissionMapper(),
        )
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

    func makeGroupMemberManageViewModel() -> GroupMemberManageViewModel {
        return GroupMemberManageViewModel(groupManageUseCase: groupManageUseCase)
    }
    
    func makeStampInfoViewModel() -> StampInfoViewModel {
        return StampInfoViewModel(
            missionUseCase: missionUseCase,
            myPageUseCase: myPageUseCase
        )
    }

    func makeNoticeListViewModel() -> NoticeListViewModel {
        return NoticeListViewModel(useCase: noticeUseCase)
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

    func makeStampBoardViewController() -> StampBoardViewController {
        let viewModel = makeStampBoardViewModel()
        return StampBoardViewController(viewModel: viewModel)
    }

    func makeProfileViewController() -> ProfileViewController {
        let viewModel = makeProfileViewModel()
        return ProfileViewController(viewModel: viewModel)
    }
    
    func makeOnboardingViewController() -> OnboardingViewController {
        let viewModel = makeOnboardingViewModel()
        return OnboardingViewController(viewModel: viewModel)
    }

    func makeMyMissionViewController() -> MyMissionViewController {
        let viewModel = makeMyMissionViewModel()
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
    
    func makeGroupMemberManageViewController() -> GroupMemberManageViewController {
        let viewModel = makeGroupMemberManageViewModel()
        return GroupMemberManageViewController(viewModel: viewModel)
    }

    func makeStampInfoViewController(stampType: StampType) -> StampInfoViewController {
        let viewModel = makeStampInfoViewModel()
        return StampInfoViewController(viewModel: viewModel, stampType: stampType)
    }

    func makeNoticeListViewController() -> NoticeListViewController {
        let viewModel = makeNoticeListViewModel()
        return NoticeListViewController(viewModel: viewModel)
    }

    // MARK: - Singleton
    static let shared = DIContainer()
    private init() {}
}
