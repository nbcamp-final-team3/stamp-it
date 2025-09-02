//
//  SceneDelegate.swift
//  StampIt-Project
//
//  Created by iOS study on 6/4/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // 딥링크 버퍼
    private var pendingDeepLinkURL: URL?
    
    // 탭바 준비 상태 추적
    private var isTabBarReady = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        // 앱이 종료된 상태 일때 / 버퍼에 보관
        if let url = connectionOptions.urlContexts.first?.url {

            pendingDeepLinkURL = url
        }

        // 1. VersionCheckViewModel 인스턴스 준비
        let versionCheckViewModel = VersionCheckViewModel()

        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        // TokenCoordinator 초기화 (FCM 토큰 이벤트 구독 시작)
        _ = DIContainer.shared.tokenCoordinator

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

            // 탭바 준비 상태 리셋
            self.isTabBarReady = false
            
            // 탭바 준비 완료 노티피케이션 구독
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handleTabBarReady),
                name: .mainUITabReady,
                object: nil
            )
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        
        // 노티피케이션 구독 해제
        NotificationCenter.default.removeObserver(self, name: .mainUITabReady, object: nil)
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

    /// 앱이 이미 실행 중일 때 들어오는 URL 처리
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        enqueueDeepLink(url)
    }

    // MARK: - 탭바 준비 완료 처리
    @objc private func handleTabBarReady() {
        print("🔗 탭바 준비 완료 - 딥링크 처리 가능")
        isTabBarReady = true
        processPendingDeepLink()
    }

    // MARK: - 버퍼 및 조건 처리
    private func processPendingDeepLink() {
        // 탭바가 준비되지 않았으면 보류
        guard isTabBarReady else {
            print("🔗 탭바가 아직 준비되지 않음 - 딥링크 처리 보류")
            return
        }
        
        // 딥링크 URL이 없으면 종료
        guard let url = pendingDeepLinkURL else {
            print("🔗 보류 중인 딥링크 없음")
            return
        }

        // 네비게이션 가능한 상태인지 확인
        guard mainUINavigable() else {
            print("🔗 네비게이션이 아직 준비되지 않음 - 딥링크 처리 보류")
            return
        }
        
        print("🔗 보류 중인 딥링크 처리 시작: \(url.absoluteString)")
        
        // 소비 후 처리
        pendingDeepLinkURL = nil
        handleDeepLink(by: url)
    }

    /// URL 딥링크 라우팅
    func handleDeepLink(by url: URL) {
        print("🔗 딥링크 처리 시작: \(url.absoluteString)")

        let container = DIContainer.shared
        let success = DeepLinkManager.shared.handleURL(url, in: window, container: container)

        if !success {
            print("❌ 딥링크 처리 실패")
        }
    }


    // 공통 사용 묶음 메서드
    func enqueueDeepLink(_ url: URL) {
        pendingDeepLinkURL = url
        processPendingDeepLink()
    }

    // 탭바+네비 존재 여부 체크
    private func mainUINavigable() -> Bool {
        guard let tab = window?.rootViewController as? UITabBarController,
              let _ = tab.selectedViewController as? UINavigationController else {
            return false
        }
        return true
    }
}

