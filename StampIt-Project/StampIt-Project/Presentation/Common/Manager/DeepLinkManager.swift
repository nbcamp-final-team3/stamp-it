//
//  DeepLinkManager.swift
//  StampIt-Project
//
//  Created by iOS study on 7/8/25.
//

import Foundation
import UIKit

// MARK: - DeepLink Error
enum DeepLinkError: Error, LocalizedError {
    case invalidURL
    case invalidFormat
    case invalidCategory
    case unsupportedCategory
    case navigationFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다"
        case .invalidFormat:
            return "잘못된 URL 형식입니다"
        case .invalidCategory:
            return "지원하지 않는 카테고리입니다"
        case .unsupportedCategory:
            return "현재 지원하지 않는 기능입니다"
        case .navigationFailed:
            return "화면 이동에 실패했습니다"
        }
    }
}

// MARK: - DeepLink Enum
enum DeepLink {
    case newMission
    case missionRequest
    case member
    case invite(String)
    
    // MARK: - Throwing Initializer
    init(url: URL) throws {
        // URL에서 scheme 부분을 제거하고 경로만 추출
        let urlString = url.absoluteString
        guard let schemeRange = urlString.range(of: "://") else {
            throw DeepLinkError.invalidURL
        }
        
        let pathString = String(urlString[schemeRange.upperBound...])
        let comps = pathString.components(separatedBy: "/").filter { !$0.isEmpty }
        
        print("🔍 URL 파싱 디버그:")
        print("   - 전체 URL: \(urlString)")
        print("   - scheme 제거 후: '\(pathString)'")
        print("   - 분할된 comps: \(comps)")
        print("   - comps.count: \(comps.count)")
        
        guard !comps.isEmpty else {
            throw DeepLinkError.invalidFormat
        }
        
        let categoryRawValue = comps[0]
        
        // 카테고리별 처리
        switch categoryRawValue {
        case "newMission":
            self = .newMission
        case "missionRequest":
            self = .missionRequest
        case "member":
            self = .member
        case "invite":
            // 초대 코드가 있는지 확인
            if comps.count > 1 {
                let inviteCode = comps[1]
                self = .invite(inviteCode)
            } else {
                throw DeepLinkError.invalidFormat
            }
        default:
            throw DeepLinkError.invalidCategory
        }
    }
    
    // MARK: - URL 생성
    var url: URL? {
        let scheme = "stamp-it"
        let path: String
        
        switch self {
        case .newMission:
            path = "/newMission"
        case .missionRequest:
            path = "/missionRequest"
        case .member:
            path = "/member"
        case .invite(let inviteCode):
            path = "/invite/\(inviteCode)"
        }
        
        return URL(string: "\(scheme)://\(path)")
    }
}

// MARK: - DeepLink Manager
final class DeepLinkManager {
    // 딥링크 버퍼
    var pendingDeepLinkURL: URL?

    // 탭바 준비 상태 추적
    var isTabBarReady = false

    static let shared = DeepLinkManager()
    private init() {
        // 탭바 준비 완료 노티피케이션 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTabBarReady),
            name: .mainUITabReady,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    /// 딥링크 URL을 파싱하여 DeepLink 객체로 변환
    func parse(url: URL) throws -> DeepLink {
        return try DeepLink(url: url)
    }

    /// 딥링크를 기반으로 적절한 화면으로 이동
    func handleDeepLink(_ deepLink: DeepLink, in window: UIWindow?, container: DIContainer) throws {
        print("🔗 딥링크 처리 시작: \(deepLink)")

        // 1. 탭바 컨트롤러 찾기
        guard let tab = window?.rootViewController as? UITabBarController else {
            print("❌ 딥링크 처리 실패: 탭바 컨트롤러를 찾을 수 없습니다")
            throw DeepLinkError.navigationFailed
        }

        // 2. 네비게이션 컨트롤러 찾기
        guard let nav = tab.selectedViewController as? UINavigationController else {
            print("❌ 딥링크 처리 실패: 네비게이션 컨트롤러를 찾을 수 없습니다")
            throw DeepLinkError.navigationFailed
        }

        // 3. 딥링크 타입에 따른 화면 이동
        switch deepLink {
        case .newMission:
            print("🔗 새 미션 화면으로 이동")
            let homeVC = container.makeHomeViewController()
            nav.pushViewController(homeVC, animated: true)

        case .missionRequest:
            print("🔗 미션 요청 화면으로 이동")
            let missionListVC = container.makeMissionListViewController()
            nav.pushViewController(missionListVC, animated: true)

        case .member:
            print("🔗 멤버 관리 화면으로 이동")
            let groupMemberManageVC = container.makeGroupMemberManageViewController()
            nav.pushViewController(groupMemberManageVC, animated: true)

        case .invite(let inviteCode):
            print("🔗 초대 받기 화면으로 이동 (초대 코드: \(inviteCode))")

            // 이미 초대받기 화면에 있는지 확인
            if let topVC = nav.topViewController,
               topVC is ReceiveInviteViewController {
                print("🔗 이미 초대받기 화면에 있습니다. 초대 코드만 업데이트")
                // 기존 화면의 초대 코드 업데이트
                if let receiveVC = topVC as? ReceiveInviteViewController {
                    receiveVC.setInviteCodeFromDeepLink(inviteCode)
                }
                return
            }

            // 초대받기 화면으로 이동
            let receiveInviteVC = container.makeReceiveInviteViewController()
            // 딥링크로 받은 초대 코드를 ViewModel에 전달
            receiveInviteVC.setInviteCodeFromDeepLink(inviteCode)

            // 기존 스택을 정리하고 초대받기 화면으로 이동
            nav.setViewControllers([nav.viewControllers.first!], animated: false)
            nav.pushViewController(receiveInviteVC, animated: true)
        }
    }

    /// URL 문자열로부터 딥링크 처리
    func handleURLString(_ urlString: String, in window: UIWindow?, container: DIContainer) -> Bool {
        guard let url = URL(string: urlString) else {
            print("❌ URL 문자열 파싱 실패: \(urlString)")
            return false
        }

        return handleURL(url, in: window, container: container)
    }

    /// URL로부터 딥링크 처리
    func handleURL(_ url: URL, in window: UIWindow?, container: DIContainer) -> Bool {
        print("🔗 딥링크 URL 처리 시작: \(url.absoluteString)")

        do {
            let deepLink = try parse(url: url)
            try handleDeepLink(deepLink, in: window, container: container)
            return true
        } catch {
            print("❌ 딥링크 처리 실패: \(error.localizedDescription)")
            return false
        }
    }

    /// 알림에서 딥링크 처리
    func handleDeeplinkFromNotification(_ userInfo: [AnyHashable: Any], in window: UIWindow?, container: DIContainer) -> Bool {
        guard let linkStr = userInfo["deeplink"] as? String else {
            print("❌ 알림에서 딥링크 정보를 찾을 수 없습니다")
            return false
        }

        return handleURLString(linkStr, in: window, container: container)
    }

    /// AppDelegate에서 호출하는 통합 딥링크 처리
    func handleDeepLinkFromAppDelegate(_ url: URL) -> Bool {
        print("🔗 AppDelegate에서 딥링크 처리: \(url.absoluteString)")
        
        // 딥링크를 버퍼에 저장
        pendingDeepLinkURL = url
        
        // 현재 window와 container 가져오기
        guard let window = getCurrentWindow(),
              let container = getDIContainer() else {
            print("❌ Window 또는 DIContainer를 찾을 수 없습니다")
            return false
        }
        
        // 딥링크 처리 시도
        return processDeepLinkIfReady(in: window, container: container)
    }
    
    /// 알림에서 딥링크 처리 (AppDelegate에서 호출)
    func handleDeepLinkFromNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        print("🔗 알림에서 딥링크 처리")
        
        // 딥링크 URL 추출
        guard let linkStr = (userInfo["deeplink"] as? String) ?? (userInfo["url"] as? String),
              let url = URL(string: linkStr) else {
            print("❌ 알림에서 딥링크 정보를 찾을 수 없습니다")
            return false
        }
        
        // 딥링크를 버퍼에 저장
        pendingDeepLinkURL = url
        
        // 현재 window와 container 가져오기
        guard let window = getCurrentWindow(),
              let container = getDIContainer() else {
            print("❌ Window 또는 DIContainer를 찾을 수 없습니다")
            return false
        }
        
        // 딥링크 처리 시도
        return processDeepLinkIfReady(in: window, container: container)
    }
    

    
    // MARK: - Private Helper Methods
    
    /// 딥링크가 준비되면 처리
    private func processDeepLinkIfReady(in window: UIWindow?, container: DIContainer) -> Bool {
        // 탭바가 준비되지 않았으면 보류
        guard isTabBarReady else {
            print("🔗 탭바가 아직 준비되지 않음 - 딥링크 처리 보류")
            return true // 보류는 성공으로 간주
        }
        
        // 딥링크 URL이 없으면 종료
        guard let url = pendingDeepLinkURL else {
            print("🔗 보류 중인 딥링크 없음")
            return false
        }
        
        // 네비게이션 가능한 상태인지 확인
        guard isMainUINavigable(in: window) else {
            print("🔗 네비게이션이 아직 준비되지 않음 - 딥링크 처리 보류")
            return true // 보류는 성공으로 간주
        }
        
        print("🔗 보류 중인 딥링크 처리 시작: \(url.absoluteString)")
        
        // 소비 후 처리
        pendingDeepLinkURL = nil
        return handleURL(url, in: window, container: container)
    }
    
    /// 현재 window 가져오기
    private func getCurrentWindow() -> UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = scene.delegate as? SceneDelegate else {
            return nil
        }
        return delegate.window
    }
    
    /// DIContainer 가져오기
    private func getDIContainer() -> DIContainer? {
        return DIContainer.shared
    }
    
    /// 탭바+네비 존재 여부 체크
    private func isMainUINavigable(in window: UIWindow?) -> Bool {
        guard let tab = window?.rootViewController as? UITabBarController,
              let _ = tab.selectedViewController as? UINavigationController else {
            return false
        }
        return true
    }
    
    // MARK: - NotificationCenter Observer
    
    @objc private func handleTabBarReady() {
        print("🔗 탭바 준비 완료 - 딥링크 처리 가능")
        isTabBarReady = true
        
        // 보류 중인 딥링크가 있으면 처리
        guard let window = getCurrentWindow(),
              let container = getDIContainer() else { return }
        
        _ = processDeepLinkIfReady(in: window, container: container)
    }
}
