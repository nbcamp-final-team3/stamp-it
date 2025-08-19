//
//  StampBoardViewController+Transition.swift
//  StampIt-Project
//
//  Created by kingj on 8/18/25.
//

import UIKit

final class StampPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toVC = transitionContext.viewController(forKey: .to) as? StampInfoViewController else { return }

        let containerView = transitionContext.containerView
        containerView.backgroundColor = .black.withAlphaComponent(0.3)

        let finalFrame = transitionContext.finalFrame(for: toVC)
        toVC.view.frame = finalFrame
        containerView.addSubview(toVC.view)

        toVC.view.layoutIfNeeded()

        let circleView = toVC.circleView

        // 3D Y축 회전 설정 (뒤집혀 있는 상태)
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 1000   // 원근감 추가
        transform = CATransform3DRotate(transform, .pi, 0, 1, 0) // y축 기준 180도 회전
        circleView.layer.transform = transform

        // 애니메이션
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseOut]
        ) {
            circleView.layer.transform = CATransform3DIdentity // 원래 상태로 되돌림
        } completion: { _ in
            transitionContext.completeTransition(true)
        }
    }
}

final class StampDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.6
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? StampInfoViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let circleView = fromVC.circleView

        // 원근감 추가
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 1000

        // 애니메이션
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                transform = CATransform3DRotate(transform, .pi, 0, 1, 0) // y축 기준 180도 회전
                circleView.layer.transform = transform

                // 투명도 감소
                fromVC.view.alpha = 0
            }, completion: { _ in
                fromVC.view.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}
