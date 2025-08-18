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
    case group(String)  // groupId를 포함한 그룹 딥링크
    case memberJoined  // 🎯 groupId 파라미터 제거하여 단순화
    
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
        
        let categoryRawValue = comps[0]
        
        // 카테고리별 처리
        switch categoryRawValue {
        case "newMission":
            self = .newMission
        case "missionRequest":
            self = .missionRequest
        case "member":
            self = .member
        case "group":
            // group/{groupId} 패턴 처리
            if comps.count >= 2 {
                let groupId = comps[1]
                self = .group(groupId)
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
        case .group(let groupId):
            path = "/group/\(groupId)"
        case .memberJoined:
            path = "/member_joined"  // 🎯 그룹 ID 없이 단순화
        }
        
        return URL(string: "\(scheme)://\(path)")
    }
}

// MARK: - DeepLink Manager
final class DeepLinkManager {
    static let shared = DeepLinkManager()
    private init() {}
    
    // MARK: - Public Methods
    
    /// 딥링크 URL을 파싱하여 DeepLink 객체로 변환
    func parse(url: URL) throws -> DeepLink {
        return try DeepLink(url: url)
    }
    
    /// 딥링크 처리를 위한 안전한 파싱 메서드
    func safeParse(url: URL) -> DeepLink? {
        do {
            let deepLink = try parse(url: url)
            print("✅ 딥링크 파싱 성공: \(deepLink)")
            return deepLink
        } catch {
            print("❌ 딥링크 파싱 실패: \(error.localizedDescription)")
            return nil
        }
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
        case .group(let groupId):
            print("�� 그룹 멤버 관리 화면으로 이동 (그룹 ID: \(groupId))")
            let groupMemberManageVC = container.makeGroupMemberManageViewController(groupId: groupId)
            nav.pushViewController(groupMemberManageVC, animated: true)
        case .memberJoined:
            print("🔗 그룹 멤버 가입 알림 처리: 멤버 관리 화면으로 이동")
            // 🎯 그룹 멤버 관리 화면으로 이동 (해당 그룹 선택)
            let groupMemberManageVC = container.makeGroupMemberManageViewController()
            nav.pushViewController(groupMemberManageVC, animated: true)
            print("✅ 그룹 멤버 가입 알림 처리 완료 - 멤버 관리 화면으로 이동")
        }
    }
    
    // MARK: - 딥링크 URL 생성 메서드
    
    /// 그룹 관련 딥링크 URL 생성
    func createGroupDeepLink(groupId: String) -> String {
        let deepLinkURL = "stamp-it://group/\(groupId)"
        print("🔗 그룹 딥링크 생성: \(deepLinkURL)")
        return deepLinkURL
    }
    
    /// 미션 관련 딥링크 URL 생성
    func createMissionDeepLink(missionId: String) -> String {
        let deepLinkURL = "stamp-it://mission/\(missionId)"
        print("🔗 미션 딥링크 생성: \(deepLinkURL)")
        return deepLinkURL
    }
    
    /// 멤버 관련 딥링크 URL 생성
    func createMemberDeepLink() -> String {
        let deepLinkURL = "stamp-it://member"
        print("🔗 멤버 딥링크 생성: \(deepLinkURL)")
        return deepLinkURL
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
}

// MARK: - Convenience Extensions
extension DeepLink {
    /// 딥링크 타입을 문자열로 반환
    var type: String {
        switch self {
        case .newMission:
            return "newMission"
        case .missionRequest:
            return "missionRequest"
        case .member:
            return "member"
        case .group(let groupId):
            return "group/\(groupId)"
        case .memberJoined:
            return "memberJoined"
        }
    }
} 
