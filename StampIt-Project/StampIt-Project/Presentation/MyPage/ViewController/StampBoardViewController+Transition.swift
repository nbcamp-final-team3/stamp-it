//
//  StampBoardViewController+Transition.swift
//  StampIt-Project
//
//  Created by kingj on 8/18/25.
//

import UIKit
import RxSwift

final class StampPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let duration: TimeInterval = 0.6
    private var animationDisposable: Disposable?

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        return duration
    }

    func animateTransition(
        using context: UIViewControllerContextTransitioning
    ) {
        guard let stampInfoVC = context.viewController(
            forKey: .to
        ) as? StampInfoViewController else {
            context.completeTransition(false)
            return
        }

        let containerView = context.containerView
        containerView.backgroundColor = .black.withAlphaComponent(0.3)

        let popupView = stampInfoVC.view!
        containerView.addSubview(popupView)
        popupView.frame = containerView.bounds
        popupView.layoutIfNeeded()

        let cardView = stampInfoVC.cardContainerView
        let frontView = stampInfoVC.frontInfoView
        let backView = stampInfoVC.backImageView

        // 초기 각도 세팅 (back 먼저 보이도록)
        var currentAngle: CGFloat = -180

        frontView.isHidden = true
        backView.isHidden = true

        // 데이터 바인딩 완료 후 애니메이션 실행
        animationDisposable = stampInfoVC.animationTrigger
            .take(1)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak stampInfoVC] in
                // 3D Y축 회전 설정
                var perspective = CATransform3DIdentity

                let displayLink = CADisplayLink(
                    target: AnimationWrapper { [weak stampInfoVC] link in
                        guard let stampInfoVC else {
                            link.invalidate()
                            return
                        }

                        currentAngle += 6 // 60fps 기준 → 360도 / 6 = 60프레임

                        let radians = (currentAngle / 180) * .pi

                        // 회전 적용
                        frontView.layer.transform = CATransform3DRotate(perspective, radians, 0, 1, 0)
                        backView.layer.transform = CATransform3DRotate(perspective, radians + .pi, 0, 1, 0)

                        // 뒷면 → 앞면 전환 타이밍
                        let mod = currentAngle.truncatingRemainder(dividingBy: 360)
                        if mod >= -90 && mod < 90 {
                            frontView.isHidden = false
                            backView.isHidden = true
                        } else {
                            frontView.isHidden = true
                            backView.isHidden = false
                        }

                        if currentAngle >= 0 {
                            link.invalidate()

                            // 최종 상태 고정
                            frontView.isHidden = false
                            backView.isHidden = true
                            frontView.layer.transform = CATransform3DIdentity
                            backView.layer.transform = CATransform3DRotate(perspective, .pi, 0, 1, 0)
                            cardView.transform = .identity

                            context.completeTransition(true)
                        }
                    }, selector: #selector(AnimationWrapper.tick))

                displayLink.add(to: .main, forMode: .common)
            })
    }

    deinit {
        animationDisposable?.dispose()
    }
}

final class StampDismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let duration: TimeInterval = 0.6
    private var displayLink: CADisplayLink?

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let stampInfoVC = context.viewController(forKey: .from) as? StampInfoViewController else {
            context.completeTransition(false)
            return
        }

        let popupView = stampInfoVC.view!
        let frontView = stampInfoVC.frontInfoView
        let backView = stampInfoVC.backImageView

        // 두 면 모두 보이게
        frontView.isHidden = false
        backView.isHidden = false

        // 초기 각도 세팅 (front 먼저 보이도록)
        var currentAngle: CGFloat = 0
        let totalAngle: CGFloat = 180  // 0 → 180

        let totalFrames: CGFloat = 50
        let angleStep = totalAngle / totalFrames
        var currentFrame: CGFloat = 0

        displayLink = CADisplayLink(target: AnimationWrapper { [weak self, weak stampInfoVC] link in
            guard let stampInfoVC else {
                link.invalidate()
                return
            }

            currentFrame += 1
            currentAngle += angleStep
            let radians = (currentAngle / 180) * .pi

            // 3D Y축 회전 설정
            var perspective = CATransform3DIdentity
            frontView.layer.transform = CATransform3DRotate(perspective, radians, 0, 1, 0)
            backView.layer.transform = CATransform3DRotate(perspective, radians + .pi, 0, 1, 0)

            // 앞뒤면 전환
            let mod = currentAngle.truncatingRemainder(dividingBy: 360)
            if mod >= 90 && mod < 270 {
                frontView.isHidden = true
                backView.isHidden = false
            } else {
                frontView.isHidden = false
                backView.isHidden = true
            }

            // 점진적 축소 + 페이드아웃
            popupView.alpha = 1.0 - (currentFrame / totalFrames)

            if currentFrame >= totalFrames {
                link.invalidate()
                self?.displayLink = nil

                context.completeTransition(true)
            }
        }, selector: #selector(AnimationWrapper.tick))

        displayLink?.add(to: .main, forMode: .common)
    }
}

class AnimationWrapper {
    let block: (CADisplayLink) -> Void
    init(_ block: @escaping (CADisplayLink) -> Void) {
        self.block = block
    }

    @objc func tick(_ sender: CADisplayLink) {
        block(sender)
    }
}
