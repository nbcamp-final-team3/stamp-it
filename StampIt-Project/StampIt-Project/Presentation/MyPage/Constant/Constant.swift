//
//  Constants.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import UIKit

// MARK: - Stamp

extension StampType {
    static let imageSize: CGFloat = 53
    
    static func from(_ index: Int) -> StampType {
        switch index {
        case 0: return .red
        case 1: return .blue
        case 2: return .yellow
        case 3: return .purple
        default: return .gray
        }
    }
}

enum DefaultStamp {
    static let userID: String = "Unknown"
    static let groupID: String = "Unknown"
    static let missionID: String = "Unknown"
    static let assignedBy: String = "Unknown"
    static let month: String = "0000-00"
    static let zigzagIndex: Int = -1
    static let maxStamps: Int = .zero
}

// MARK: - MyPage

enum MyPage {
    enum Text {
        static let fontSizeSmall: CGFloat = 14
        static let fontSizeMedium: CGFloat = 16
        static let fontSizeLarge: CGFloat = 20
    }

    enum Image {
        static let imageSizeSmall: CGFloat = 18
        static let imageSizeLarge: CGFloat = 70
    }

    enum User {
        static let edit: String = "edit"
        static let group: String = "그룹이름"
        static let user: String = "유저이름"
    }
    
    enum TableView {
        static let headerHeightLow: CGFloat = 35
        static let headerHeightHigh: CGFloat = 45
        static let cellHeight: CGFloat = 58
    }
    
    enum StampBoard {
        static let collected: String = "내가 모은 스탬프"
        static let completed: String = "완성한 스탬프판"
        static let unit: String = "개"
        static let slash: String = "/"
        static let vertical: CGFloat = 6
        static let height: CGFloat = 72
    }
}

enum TabType: Int {
    case stampBoard = 0
    case profile
    
    var title: String {
        switch self {
        case .profile: return "프로필"
        case .stampBoard: return "스탬프판"
        }
    }
}

// MARK: - Navigation

enum Navigation {
    static let fontSize: CGFloat = 24
    static let height: Double = 68
    static let spacing: CGFloat = 12
    static let horizontal: CGFloat = 16
    static let backButton: String = "backButton"
    static let bellButton: String = "bellButton"
    static let buttonSize: CGFloat = 24
    static let appLogo: String = "AppLogo"
    static let appLogoWidth: CGFloat = 125
    static let appLogoHeight: CGFloat = 42
}

// MARK: - StampBoard

enum StampBoard: Int {
    case red = 0
    case blue
    case yellow
    case purple

    var background: UIColor {
        switch self {
        case .red: return .red50
        case .blue: return .blue50
        case .yellow: return .yellow50
        case .purple: return .purple50
        }
    }

    var pageBar: UIColor {
        switch self {
        case .red: return .red200
        case .blue: return .blue200
        case .yellow: return .yellow200
        case .purple: return .purple200
        }
    }
}

extension StampBoard {
    static var totalPage: Int { 4 }
}
