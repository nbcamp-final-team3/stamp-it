//
//  MainTabBarController.swift
//  StampIt-Project
//
//  Created by kingj on 6/18/25.
//

import UIKit

final class MainTabBarController: UITabBarController {
    
    // MARK: - Properties
    
    private let container: DIContainer
    
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
        setupTabs()
    }
    
    // MARK: - Methods
    
    private func setupTabs() {
        let homeVC = container.makeHomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(named: "tabBarHome")!.withTintColor(.red),
            tag: 0
        )
        
        let missionVC = container.makeMissionListViewController()
        let missionNav = UINavigationController(rootViewController: missionVC)
        missionNav.tabBarItem = UITabBarItem(
            title: "미션",
            image: UIImage(named: "tabBarMission")!.withTintColor(.red),
            tag: 1
        )
        
        let myPageVC = container.makeMyPageViewController()
        let myPageNav = UINavigationController(rootViewController: myPageVC)
        myPageNav.tabBarItem = UITabBarItem(
            title: "마이",
            image: UIImage(named: "tabBarMyPage")!.withTintColor(.red),
            tag: 2
        )
        
        viewControllers = [
            homeNav,
            missionNav,
            myPageNav
        ]
    }
}
