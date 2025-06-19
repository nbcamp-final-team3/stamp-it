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
        setupTabs()
        bindTapSelection()
    }
    
    // MARK: - Methods
    
    private func bindTapSelection() {
        rx.didSelect
            .compactMap { [weak self] viewController in
                self?.viewControllers?.firstIndex(of: viewController)
            }.subscribe(with: self) { owner, index in
                owner.updateTabBarImage(selectedIndex: index)
            }.disposed(by: disposeBag)
    }
    
    private func updateTabBarImage(selectedIndex: Int) {
        guard let tabItems = tabBar.items else { return }
        
        for (index, item) in tabItems.enumerated() {
            if index == selectedIndex {
                item.image = UIImage(named: selectedImageName(for: index))?.withRenderingMode(.alwaysOriginal)
            } else {
                item.image = UIImage(named: defaultImageName(for: index))?.withRenderingMode(.alwaysOriginal)
            }
        }
    }
    
    private func selectedImageName(for index: Int) -> String {
        switch index {
        case 0: return "tabBarHomeTapped"
        case 1: return "tabBarMissionTapped"
        case 2: return "tabBarMyPageTapped"
        default: return ""
        }
    }
    
    private func defaultImageName(for index: Int) -> String {
        switch index {
        case 0: return "tabBarHome"
        case 1: return "tabBarMission"
        case 2: return "tabBarMyPage"
        default: return ""
        }
    }
    
    private func setupTabs() {
        let homeVC = container.makeHomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "홈",
            image: UIImage(named: "tabBarHomeTapped")!.withTintColor(.red),
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
