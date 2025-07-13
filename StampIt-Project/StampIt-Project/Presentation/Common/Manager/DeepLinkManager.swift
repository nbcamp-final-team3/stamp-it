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
    case invalidID
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
        case .invalidID:
            return "유효하지 않은 ID입니다"
        case .unsupportedCategory:
            return "현재 지원하지 않는 기능입니다"
        case .navigationFailed:
            return "화면 이동에 실패했습니다"
        }
    }
}

// MARK: - DeepLink Enum
enum DeepLink {
    case newMission(id: String)
    case missionRequest(id: String)
    
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
        
        // 기본 URL 형식 검증
        guard comps.count == 2 else {
            print("❌ URL 형식 오류: comps.count = \(comps.count), 예상: 2")
            throw DeepLinkError.invalidFormat
        }
        
        let categoryRawValue = comps[0]
        let idString = comps[1]
        
        // ID 검증 (빈 문자열 체크)
        guard !idString.isEmpty else {
            throw DeepLinkError.invalidID
        }
        
        // 카테고리 매핑
        guard let category = NoticeCategory(rawValue: categoryRawValue) else {
            throw DeepLinkError.invalidCategory
        }
        
        // 카테고리별 처리
        switch category {
        case .newMission:
            self = .newMission(id: idString)
        case .missionRequest:
            self = .missionRequest(id: idString)
        case .member:
            throw DeepLinkError.unsupportedCategory
        case .unknown:
            throw DeepLinkError.invalidCategory
        }
    }
    
    // MARK: - URL 생성
    var url: URL? {
        let scheme = "stamp-it"
        let path: String
        
        switch self {
        case .newMission(let id):
            path = "/newMission/\(id)"
        case .missionRequest(let id):
            path = "/missionRequest/\(id)"
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
    /// - Parameter url: 파싱할 URL
    /// - Returns: 파싱된 DeepLink 객체
    /// - Throws: DeepLinkError
    func parse(url: URL) throws -> DeepLink {
        return try DeepLink(url: url)
    }
    
    /// 딥링크 처리를 위한 안전한 파싱 메서드
    /// - Parameter url: 파싱할 URL
    /// - Returns: 파싱 결과 (성공 시 DeepLink, 실패 시 에러 로그)
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
    /// - Parameters:
    ///   - deepLink: 처리할 딥링크
    ///   - window: 현재 윈도우
    ///   - container: DI 컨테이너
    /// - Throws: DeepLinkError
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
        case .newMission(let id):
            print("🔗 새 미션 화면으로 이동: \(id)")
            let homeVC = container.makeHomeViewController()
            nav.pushViewController(homeVC, animated: true)
            
        case .missionRequest(let id):
            print("🔗 미션 요청 화면으로 이동: \(id)")
            let missionListVC = container.makeMissionListViewController()
            nav.pushViewController(missionListVC, animated: true)
        }
    }
    
    /// URL 문자열로부터 딥링크 처리
    /// - Parameters:
    ///   - urlString: URL 문자열
    ///   - window: 현재 윈도우
    ///   - container: DI 컨테이너
    /// - Returns: 처리 성공 여부
    func handleURLString(_ urlString: String, in window: UIWindow?, container: DIContainer) -> Bool {
        guard let url = URL(string: urlString) else {
            print("❌ URL 문자열 파싱 실패: \(urlString)")
            return false
        }
        
        return handleURL(url, in: window, container: container)
    }
    
    /// URL로부터 딥링크 처리
    /// - Parameters:
    ///   - url: 처리할 URL
    ///   - window: 현재 윈도우
    ///   - container: DI 컨테이너
    /// - Returns: 처리 성공 여부
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
    /// - Parameters:
    ///   - userInfo: 알림 정보
    ///   - window: 현재 윈도우
    ///   - container: DI 컨테이너
    /// - Returns: 처리 성공 여부
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
        }
    }
    
    /// 딥링크 ID를 반환
    var id: String {
        switch self {
        case .newMission(let id):
            return id
        case .missionRequest(let id):
            return id
        }
    }
} 
