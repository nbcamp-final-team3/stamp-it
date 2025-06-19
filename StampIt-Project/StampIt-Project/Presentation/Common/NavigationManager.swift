//
//  NavigationManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/19/25.
//

import UIKit

final class NavigationManager {
    static let shared = NavigationManager()
    private init() {}

    // TODO: 현재는 push는 NavigationController를 사용해서 직접 push, 추후 커스텀 애니메이션 추가, 화면 전환 상황 추가할 때 일괄 변경되거나 push가 삭제될 예정
    // 커스텀 전환 애니메이션 (슬라이드+페이드)
    private func makeDefaultTransition(duration: CFTimeInterval = 0.32) -> CATransition {
        let transition = CATransition()
        transition.duration = duration
        transition.type = .push
        transition.subtype = .fromRight
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.fillMode = .forwards
        transition.isRemovedOnCompletion = true
        return transition
    }

    // 1. Push 전환 (항상 커스텀 애니메이션)
    func push(
        to viewController: UIViewController,
        from: UIViewController
    ) {
        guard let navigationController = from.navigationController else { return }
        let transition = makeDefaultTransition()
        navigationController.view.layer.add(transition, forKey: kCATransition)
        navigationController.pushViewController(viewController, animated: false)
    }

    // 2. Modal 전환 (항상 커스텀 애니메이션)
    func present(
        viewController: UIViewController,
        from: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        let transition = makeDefaultTransition()
        from.view.window?.layer.add(transition, forKey: kCATransition)
        from.present(viewController, animated: false, completion: completion)
    }

    // 3. 탭 전환 (항상 커스텀 애니메이션)
    func switchTab(
        to index: Int,
        in tabBarController: UITabBarController
    ) {
        guard let viewControllers = tabBarController.viewControllers,
              index < viewControllers.count,
              let fromView = tabBarController.selectedViewController?.view,
              let toView = viewControllers[index].view,
              fromView != toView else {
            tabBarController.selectedIndex = index
            return
        }
        let transition = makeDefaultTransition()
        tabBarController.view.layer.add(transition, forKey: kCATransition)
        tabBarController.selectedIndex = index
    }
}
