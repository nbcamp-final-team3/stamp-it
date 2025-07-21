//
//  SceneDelegate.swift
//  StampIt-Project
//
//  Created by iOS study on 6/4/25.
//

import UIKit
import RxSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    private let disposeBag = DisposeBag()
    
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
                
                // 코어데이터에 샘플 미션 데이터가 없으면 마이그레이션 실행
                let missions = container.missionRepository.fetchSampleMission()
                if missions.isEmpty {
                    migrateSampleMission(container: container)
                    migrateFavorites(missions: missions, container: container)
                }
            } else {
                let onboardingVC = container.makeOnboardingViewController()
                nav = UINavigationController(rootViewController: onboardingVC)
                
                // 온보딩 시 샘플 미션 JSON 데이터를 코어데이터에 저장
                migrateSampleMission(container: container)
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
    
    // 샘플 미션 JSON 데이터를 코어데이터에 저장
    private func migrateSampleMission(container: DIContainer) {
        container.missionRepository.loadSampleMission()
            .subscribe { missions in
                container.missionRepository.saveAllSampleMissions(missions: missions)
            } onFailure: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    // UserDefaults에 저장된 favorites 정보를 코어데이터로 마이그레이션
    // 마이그레이션 완료 시 UserDefaults 삭제
    private func migrateFavorites(missions: [SampleMission], container: DIContainer) {
        let favorites = UserDefaults.standard.stringArray(forKey: "favorites")
        guard let favorites, !favorites.isEmpty else { return }
        
        favorites.forEach { favorite in
            let mission = missions.filter { $0.missionId == favorite }.first
            if let mission {
                container.missionRepository.updateSampleMission(mission: mission)
            }
        }
        
        UserDefaults.standard.removeObject(forKey: "favorites")
    }
}

