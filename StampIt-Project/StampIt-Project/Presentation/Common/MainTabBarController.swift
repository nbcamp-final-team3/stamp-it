//
//  MainTabBarController.swift
//  StampIt-Project
//
//  Created by kingj on 6/18/25.
//

import UIKit
import RxSwift
import RxCocoa

final class MainTabBarController: UITabBarController {
    
    // MARK: - Properties
    
    private let container: DIContainer
    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(container: DIContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setStyle()
        setupTabs()
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        // 상단 경계선
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .lightGray
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
    
    // MARK: - Methods
    
    private func setupTabs() {
        let homeVC = container.makeHomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(named: "tabBarHome"),
            selectedImage: UIImage(named: "tabBarHomeTapped"),
        )
        
        let missionVC = container.makeMissionListViewController()
        let missionNav = UINavigationController(rootViewController: missionVC)
        missionNav.tabBarItem = UITabBarItem(
            title: "미션",
            image: UIImage(named: "tabBarMission"),
            selectedImage: UIImage(named: "tabBarMissionTapped"),
        )
        
        let myPageVC = container.makeMyPageViewController()
        let myPageNav = UINavigationController(rootViewController: myPageVC)
        myPageNav.tabBarItem = UITabBarItem(
            title: "마이",
            image: UIImage(named: "tabBarMyPage"),
            selectedImage: UIImage(named: "tabBarMyPageTapped"),
        )
        
        viewControllers = [
            homeNav,
            missionNav,
            myPageNav
        ]
    }
}
