//
//  WindowTransitionManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/16/25.
//

import UIKit

// 공통 화면 전환 유틸리티
final class WindowTransitionManager {
    static let shared = WindowTransitionManager()
    private init() {}
    
    /// 부드러운 루트 뷰컨트롤러 전환
    func changeRootViewController(
        to viewController: UIViewController,
        duration: TimeInterval = 0.15,
        completion: (() -> Void)? = nil
    ) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = windowScene.windows.first else {
            completion?()
            return
        }
        
        // 뷰 미리 로드
        viewController.loadViewIfNeeded()
        if let navController = viewController as? UINavigationController {
            navController.viewControllers.forEach { $0.loadViewIfNeeded() }
        }
        
        // 부드러운 전환
        UIView.transition(with: window, duration: duration, options: .transitionCrossDissolve) {
            window.rootViewController = viewController
        } completion: { _ in
            window.makeKeyAndVisible()
            completion?()
        }
    }
}
