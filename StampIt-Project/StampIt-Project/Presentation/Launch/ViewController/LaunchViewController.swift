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
    private let loginUseCase = DIContainer.shared.loginUseCase
    
    // 1. 로딩 인디케이터 추가
    private let loadingIndicator = UIActivityIndicatorView(style: .large).then {
        $0.color = UIColor(named: "red400")
        $0.hidesWhenStopped = true
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
        loginUseCase.checkLaunchState()
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
        // 5. 뷰컨트롤러 미리 생성 및 로드
        let homeVC = DIContainer.shared.makeHomeViewController()
        let navController = UINavigationController(rootViewController: homeVC)
        
        // 뷰 강제 로드 (검은 화면 방지)
        navController.loadViewIfNeeded()
        homeVC.loadViewIfNeeded()
        
        changeRoot(navController)
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
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        // 6. 애니메이션 시간 단축 및 부드러운 전환
        UIView.transition(with: window, duration: 0.15, options: .transitionCrossDissolve) {
            window.rootViewController = vc
        } completion: { _ in
            window.makeKeyAndVisible()
        }
    }
}
