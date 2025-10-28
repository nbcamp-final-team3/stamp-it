//
//  ProfileTabViewController.swift
//  StampIt-Project
//
//  Created by kingj on 6/24/25.
//

import UIKit
import Then
import SnapKit
import RxSwift

final class ProfileViewController: UIViewController {
    
    // MARK: - Properties
    
    private var viewModel: ProfileViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components

    private let profileView = ProfileTab()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(
        viewModel: ProfileViewModel,
    ) {
        self.viewModel = viewModel
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
        viewModel.state.user
            .compactMap { $0 }
            .bind(with: self) { owner, user in
                owner.profileView.setUser(user)
            }.disposed(by: disposeBag)
        
        viewModel.state.alertMessage
            .bind(with: self) { owner, message in
                owner.showAlert(title: "그룹 탈퇴 실패", message: message)
            }.disposed(by: disposeBag)
        
        // 로그인 화면으로 이동
        viewModel.state.shouldNavigateToLogin
            .bind(with: self) { owner, _ in
                // 토스트가 이미 떠있으면 1.5초 뒤에 전환
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    owner.navigateToLogin()
                }
            }.disposed(by: disposeBag)

        // 확인 다이얼로그
        viewModel.state.shouldShowConfirmAlert
            .bind(with: self) { owner, alertData in
                let (title, message, action) = alertData
                owner.showConfirmAlert(title: title, message: message, confirmAction: action)
            }.disposed(by: disposeBag)
        
        // 토스트 메시지
        viewModel.state.toastMessage
            .bind(with: self) { owner, message in
                owner.showToast(message: message, type: .success)
            }.disposed(by: disposeBag)
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        view.backgroundColor = .white
        profileView.tableView.showsVerticalScrollIndicator = false
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            profileView
        ]
            .forEach { view.addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        profileView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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
    
    // MARK: - Button Action Helper
    
    private func setAction() {
        profileView.setButtonAction(target: self, action: #selector(tappedEditButton))
    }
    
    @objc private func tappedEditButton() {
        let user = viewModel.state.user.value
        guard let user else { return }
        let viewController = DIContainer.shared.makeEditProfileViewController(user: user)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // MARK: - Methods
    
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
    
    /// 로그인 화면으로 이동
    private func navigateToLogin() {
        UserCache.shared.clearCache()
        
         // UserDefaults에서 로그인 관련 정보 삭제 (필요시)
         UserDefaults.standard.removeObject(forKey: "userToken")
         UserDefaults.standard.removeObject(forKey: "lastLoginDate")
        
        let loginViewModel = DIContainer.shared.makeLoginViewModel()
        let loginVC = LoginViewController(viewModel: loginViewModel)
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

// 토스트 메시지(2초)
extension ProfileViewController {
    func showToast(message: String, type: ToastType = .success, duration: TimeInterval = 2.0) {
        let toastView = ToastView()
        toastView.show(in: self.view, duration: duration, message: message, type: type)
    }
}
