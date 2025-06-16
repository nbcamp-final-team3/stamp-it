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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLaunchState()
    }

    private func checkLaunchState() {
        loginUseCase.checkLaunchState()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                switch result.nextScreen {
                case .main:
                    self.showHome()
                case .login, .onboarding:
                    self.showLogin()
                }
            })
            .disposed(by: disposeBag)
    }

    private func showHome() {
        let homeVC = DIContainer.shared.makeHomeViewController()
        changeRoot(UINavigationController(rootViewController: homeVC))
    }

    private func showLogin() {
        let loginVC = DIContainer.shared.makeLoginViewController()
        changeRoot(UINavigationController(rootViewController: loginVC))
    }

    private func changeRoot(_ vc: UIViewController) {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = vc
            window.makeKeyAndVisible()
        }
    }
}
