//
//  LaunchViewController.swift
//  StampIt-Project
//
//  Created by iOS study on 6/16/25.
//

import Foundation
import UIKit
import RxSwift

final class LaunchViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let container: DIContainer
    
    // 1. 로딩 인디케이터 추가
    private let loadingIndicator = UIActivityIndicatorView(style: .large).then {
        $0.color = UIColor(named: "red400")
        $0.hidesWhenStopped = true
    }
    
    init(container: DIContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLaunchState()
    }
    
    // 2. UI 설정 추가
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        [loadingIndicator].forEach {
            view.addSubview($0)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // 로딩 시작
        loadingIndicator.startAnimating()
    }

    private func checkLaunchState() {
        // 3. 캐시된 사용자 정보가 있으면 바로 사용 (딜레이 제거)
        if UserCache.shared.getCurrentUser() != nil {
            showHome()
            return
        }
        
        // 4. 네트워크 조회 시 최소 딜레이 보장
        container.loginUseCase.checkLaunchState()
            .delay(.milliseconds(500), scheduler: MainScheduler.instance) // 최소 로딩 시간
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result.nextScreen {
                    case .main:
                        if let user = result.user {
                            UserCache.shared.setCurrentUser(user)
                        }
                        self.showHome()
                        
                    case .login:
                        self.showLogin()
                        
                    case .onboarding:
                        self.showOnboarding()
                    }
                },
                onError: { [weak self] error in
                    self?.showLogin()
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func showHome() {
        let tabBar = MainTabBarController()
        changeRoot(tabBar)
    }

    private func showLogin() {
        let loginVC = DIContainer.shared.makeLoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        
        // 뷰 강제 로드
        navController.loadViewIfNeeded()
        loginVC.loadViewIfNeeded()
        
        changeRoot(navController)
    }
    
    private func showOnboarding() {
        let onboardingVC = DIContainer.shared.makeOnboardingViewController()
        let navController = UINavigationController(rootViewController: onboardingVC)
        
        // 뷰 강제 로드
        navController.loadViewIfNeeded()
        onboardingVC.loadViewIfNeeded()
        
        changeRoot(navController)
    }

    private func changeRoot(_ vc: UIViewController) {
        WindowTransitionManager.shared.changeRootViewController(to: vc)
    }
}
