//
//  BaseViewController.swift
//  StampIt-Project
//
//  Created by 이부용 on 8/7/25.
//

import UIKit

class BaseViewController: UIViewController {
    private var screenStartTime: Date?
    private let analytics = AnalyticsManager.shared
    
    // 서브클래스에서 오버라이드할 화면 이름
    var screenName: String {
        return String(describing: type(of: self)).replacingOccurrences(of: "ViewController", with: "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAnalyticsGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        screenStartTime = Date()
        analytics.logScreenView(screenName: screenName)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        trackScreenTime()
    }
    
    private func setupAnalyticsGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(_:)))
        tapGesture.cancelsTouchesInView = false // 다른 터치 이벤트 방해하지 않음
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleScreenTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        analytics.logClickEvent(
            screen: screenName,
            position: "screen_tap",
            coordinates: location
        )
    }
    
    private func trackScreenTime() {
        guard let startTime = screenStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        analytics.logScreenDuration(screen: screenName, duration: duration)
    }
}
