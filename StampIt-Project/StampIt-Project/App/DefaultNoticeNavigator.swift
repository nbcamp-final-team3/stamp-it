//
//  DefaultNoticeNavigator.swift
//  StampIt-Project
//
//  Created by daeun on 8/17/25.
//

import UIKit

final class DefaultNoticeNavigator: NoticeNavigator {
    private weak var nav: UINavigationController?
    private weak var tab: UITabBarController?
    
    init(nav: UINavigationController?, tab: UITabBarController?) {
        self.nav = nav
        self.tab = tab
    }
    
    func show(by category: NoticeCategory) {
        let vc: UIViewController
        switch category {
        case .newMission:
            vc = DIContainer.shared.makeMyMissionViewController()
            nav?.pushViewController(vc, animated: true)
        case .missionRequest:
            guard let tab else { return }
            NavigationManager.shared.switchTab(to: 1, in: tab)
        case .member:
            vc = DIContainer.shared.makeGroupMemberManageViewController()
            nav?.pushViewController(vc, animated: true)
        case .unknown:
            // TODO: 알 수 없는 알림 처리
            break
        }
    }
}
