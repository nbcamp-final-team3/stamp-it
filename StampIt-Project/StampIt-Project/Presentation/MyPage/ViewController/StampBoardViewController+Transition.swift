//
//  StampBoardViewController+Transition.swift
//  StampIt-Project
//
//  Created by kingj on 8/18/25.
//

import UIKit

final class StampPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let originFrame: CGRect

    init(originFrame: CGRect) {
        self.originFrame = originFrame
    }

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

        // 시작 상태: 크기를 0.3배로 작게 만들고, 반바퀴(-180도) 회전된 상태
        let circleView = toVC.circleView
        circleView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1) // 확대 / 축소
            .concatenating(CGAffineTransform(rotationAngle: -.pi)) // 회전

        // 애니메이션 실행: 원래 크기, 원래 방향으로 돌아옴
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext), // 지속 시간
            delay: 0,
            usingSpringWithDamping: 0.7, // 튕김 효과 정도
            initialSpringVelocity: 0.3,  // 초기 속도
            options: []
        ) {
            circleView.transform = .identity
        } completion: { _ in
            transitionContext.completeTransition(true)
        }
    }
}

final class StampDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let destinationFrame: CGRect

    init(destinationFrame: CGRect) {
        self.destinationFrame = destinationFrame
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? StampInfoViewController else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        containerView.backgroundColor = .black.withAlphaComponent(0.3)
        
        let circleView = fromVC.circleView

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseIn]
        ) {
            circleView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                .concatenating(CGAffineTransform(rotationAngle: -.pi))
            fromVC.view.alpha = 0
        } completion: { _ in
            transitionContext.completeTransition(true)
        }
    }
}
