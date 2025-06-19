//
//  MyPageViewController.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import UIKit
import Then
import SnapKit
import RxSwift

final class MyPageViewController: UIViewController {
    
    // MARK: - Properties
    
    private var viewModel: MyPageViewModel
    private var container: DIContainer
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components

    private let navigationBar = DefaultNavigationBar(
        .segmentedControlTabs(
            tab1: TabType.stampBoard.title,
            tab2: TabType.profile.title
        ))
    private let stampBoardView = StampBoardTab()
    private let profileView = ProfileTab()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(
        viewModel: MyPageViewModel,
        container: DIContainer
    ) {
        self.viewModel = viewModel
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.action.accept(.viewDidLoad)
        setStyle()
        setHierarchy()
        setLayout()
        setDelegate()
        setDataSource()
        setAction()
        bind()
    }
    
    // 화면이 나타날 때마다 데이터 새로고침
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.action.accept(.viewDidLoad)
    }
    
    // MARK: - Bind
    
    private func bind() {
        
        navigationBar.tabTapped
            .bind(with: self) { owner, type in
                owner.viewModel.action.accept(
                    .tabButtonTapped(TabType(rawValue: type.rawValue)!)
                )
            }.disposed(by: disposeBag)
    
        viewModel.state.tabType
            .bind(with: self) { owner, tab in
                owner.navigationBar.updateTabTitleColor(selected: tab)
                owner.updateSelectedTab(selected: tab)
            }.disposed(by: disposeBag)
        
        viewModel.state.stickers
            .bind(with: self) { owner, stickers in
                owner.updateUI(with: stickers)
            }.disposed(by: disposeBag)
        
        viewModel.state.stickerSummary
            .bind(with: self) { owner, summary in
                owner.stampBoardView.stickerSummary.accept(summary)
            }.disposed(by: disposeBag)
        
        viewModel.state.user
            .compactMap { $0 }
            .bind(with: self) { owner, user in
                owner.profileView.setUser(user)
            }.disposed(by: disposeBag)
        
        viewModel.state.alertMessage
            .bind(with: self) { owner, message in
                owner.showAlert(title: "알림", message: message)
            }.disposed(by: disposeBag)
        
        // 로그인 화면으로 이동
        viewModel.state.shouldNavigateToLogin
            .bind(with: self) { owner, _ in
                owner.navigateToLogin()
            }.disposed(by: disposeBag)
        
        // 확인 다이얼로그
        viewModel.state.shouldShowConfirmAlert
            .bind(with: self) { owner, alertData in
                let (title, message, action) = alertData
                owner.showConfirmAlert(title: title, message: message, confirmAction: action)
            }.disposed(by: disposeBag)
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        view.backgroundColor = .white
        stampBoardView.isHidden = false
        profileView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            navigationBar,
            stampBoardView,
            profileView
        ]
            .forEach { view.addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
        }
        
        stampBoardView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.directionalHorizontalEdges.bottom.equalToSuperview()
        }
        
        profileView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.directionalHorizontalEdges.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Delegate Helper
    
    private func setDelegate() {
        profileView.tableView.delegate = self
    }

    // MARK: - DataSource Helper
    
    private func setDataSource() {
        profileView.tableView.dataSource = self
    }

    // MARK: - Snapshot
    
    private func updateUI(with stickers: [Sticker]) {
        var snapshot = NSDiffableDataSourceSnapshot<StampBoardSection, StampBoardItem>()
        snapshot.appendSections([.defaultBoard])
        snapshot.appendItems(stickers, toSection: .defaultBoard)
        stampBoardView.stickerBoardDataSource.apply(snapshot, animatingDifferences: false)
    }
    
    // MARK: - Button Action Helper
    
    private func setAction() {
        profileView.setButtonAction(target: self, action: #selector(tappedEditButton))
    }
    
    @objc private func tappedEditButton() {
        let user = viewModel.state.user.value
        guard let user else { return }
        let viewController = container.makeEditProfileViewController(user: user)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: - Methods
    
    private func updateSelectedTab(selected: TabType) {
        switch selected {
        case .stampBoard:
            stampBoardView.isHidden = false
            profileView.isHidden = true
            
        case .profile:
            stampBoardView.isHidden = true
            profileView.isHidden = false
        }
    }
    
    /// 일반 알림 다이얼로그
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    /// 확인/취소 다이얼로그
    private func showConfirmAlert(title: String, message: String, confirmAction: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "확인", style: .destructive) { _ in
            confirmAction()
        })
        
        present(alert, animated: true)
    }
    
    /// TODO: 리더 전용 메뉴 표시 (향후 기능 완성 후 활성화)
     /*
    private func showLeaderOptionsAlert() {
        let alert = UIAlertController(title: "그룹장 옵션", message: "그룹을 떠나려면 먼저 다음 작업을 수행해주세요:", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "그룹장 위임하기", style: .default) { _ in // TODO: 리더 위임 화면으로 이동
        })
        alert.addAction(UIAlertAction(title: "멤버 관리하기", style: .default) { _ in // TODO: 멤버 관리 화면으로 이동
        })
        alert.addAction(UIAlertAction(title: "계정 탈퇴 (그룹 삭제)", style: .destructive) { _ in self.deleteAccount() })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
    */
    
    /// 로그인 화면으로 이동
    private func navigateToLogin() {
        UserCache.shared.clearCache()
        
         // UserDefaults에서 로그인 관련 정보 삭제 (필요시)
         UserDefaults.standard.removeObject(forKey: "userToken")
         UserDefaults.standard.removeObject(forKey: "lastLoginDate")
        
        let loginViewModel = DIContainer.shared.makeLoginViewModel()
        let loginVC = LoginViewController(viewModel: loginViewModel, container: container)
        let navController = UINavigationController(rootViewController: loginVC)
        
        WindowTransitionManager.shared.changeRootViewController(to: navController)
    }
    
    // 외부에서 쓸 수 있는 메서드로 액션 전달 (public/internal)
    func leaveGroup() {
        viewModel.action.accept(.leaveGroupButtonTapped)
    }

    func deleteAccount() {
        viewModel.action.accept(.deleteAccountButtonTapped)
    }
    
    func logOut() {
        viewModel.action.accept(.logoutButtonTapped)
    }
}
