//
//  SceneDelegate.swift
//  StampIt-Project
//
//  Created by iOS study on 6/4/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        // 1. VersionCheckViewModel 인스턴스 준비
        let versionCheckViewModel = VersionCheckViewModel()
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        // 2. 버전 체크 먼저
        versionCheckViewModel.checkForceUpdate { [weak self] needUpdate, message in
            guard let self else { return }
            if needUpdate {
                // 3. 강제 업데이트 알럿만 띄우기 (이전 버전은 앱 사용 불가)
                let alert = UIAlertController(
                    title: "업데이트 필요",
                    message: message ?? "최신 버전으로 업데이트 해주세요!",
                    preferredStyle: .alert
                )
                let updateAction = UIAlertAction(title: "업데이트 하러가기", style: .default) { _ in
                    guard let url = URL(string: "itms-apps://itunes.apple.com/app/id6747178558") else { return }
                    DispatchQueue.main.async {
                        UIApplication.shared.open(url, options: [:], completionHandler: { success in
                            if !success {
                                print("잠시 후 다시 시도해주세요.")
                            }
                        })
                    }
                }
                alert.addAction(updateAction)
                self.window?.rootViewController = UIViewController()
                self.window?.makeKeyAndVisible()
                self.window?.rootViewController?.present(alert, animated: true)
                return
            }
            
            // 4. 정상 분기 (온보딩/런치/메인 등 기존 로직)
            let hasOnboarded = UserDefaults.standard.bool(forKey: "hasOnboarded")
            let container = DIContainer.shared
            let nav: UINavigationController
            if hasOnboarded {
                let launchVC = LaunchViewController(container: container)
                nav = UINavigationController(rootViewController: launchVC)
            } else {
                let onboardingVC = container.makeOnboardingViewController()
                nav = UINavigationController(rootViewController: onboardingVC)
            }
            self.window?.rootViewController = nav
            self.window?.makeKeyAndVisible()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    // MARK: - DeepLink Handling
    
    /// 딥링크 URL 처리
    /// - Parameter url: 처리할 URL
    func handleDeepLink(_ url: URL) {
        print("🔗 딥링크 처리 시작: \(url.absoluteString)")
        
        // 직접 moveToViewController 호출
        moveToViewController(by: url)
    }
    
    /// 알림에서 딥링크 처리
    /// - Parameter userInfo: 알림 정보
    func handleDeeplinkFromNotification(_ userInfo: [AnyHashable: Any]) {
        guard let linkStr = userInfo["deeplink"] as? String else {
            print("❌ 알림에서 딥링크 정보를 찾을 수 없습니다")
            return
        }
        
        guard let url = URL(string: linkStr) else {
            print("❌ 알림 딥링크 URL 파싱 실패: \(linkStr)")
            return
        }
        
        handleDeepLink(url)
    }
    
    /// 딥링크를 기반으로 적절한 화면으로 이동 (기존 방식)
    /// - Parameter deeplink: 처리할 딥링크 URL
    func moveToViewController(by deeplink: URL) {
        print("🔗 moveToViewController 호출: \(deeplink.absoluteString)")
        
        // 1. 탭바 컨트롤러 찾기
        guard let tab = window?.rootViewController as? UITabBarController else {
            print("❌ moveToViewController 실패: 탭바 컨트롤러를 찾을 수 없습니다")
            return
        }
        
        // 2. 탭바의 모든 뷰 컨트롤러 확인
        print("🔍 탭바의 모든 뷰 컨트롤러:")
        for (index, vc) in tab.viewControllers?.enumerated() ?? [].enumerated() {
            print("   탭[\(index)]: \(type(of: vc))")
        }
        
        // 3. 네비게이션 컨트롤러 찾기
        guard let nav = tab.selectedViewController as? UINavigationController else {
            print("❌ moveToViewController 실패: 네비게이션 컨트롤러를 찾을 수 없습니다")
            return
        }
        
        // 4. HomeViewController 찾기 (기존 인스턴스 확인용)
        guard nav.viewControllers.first is HomeViewController else {
            print("❌ moveToViewController 실패: HomeViewController를 찾을 수 없습니다")
            return
        }
        
        // 5. 새로운 뷰 컨트롤러들 생성
        let container = DIContainer.shared
        let homeVC = container.makeHomeViewController()
        let missionListVC = container.makeMissionListViewController()

        // 4. DeepLink 파싱
        guard let link = DeepLinkManager.shared.safeParse(url: deeplink) else {
            print("❌ moveToViewController 실패: 딥링크 파싱 실패")
            return
        }
        
        // 5. 딥링크 타입에 따른 화면 이동
        switch link {
        case .newMission(let id):
            print("🔗 새 미션 화면으로 이동: \(id)")
            nav.pushViewController(homeVC, animated: true)

        case .missionRequest(let id):
            print("🔗 미션 요청 화면으로 이동: \(id)")
            nav.pushViewController(missionListVC, animated: true)
        }
    }
}

