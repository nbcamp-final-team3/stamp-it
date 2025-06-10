//
//  Constants.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import Foundation

enum TabType {
    case stampBoard
    case profile
    
    var title: String {
        switch self {
        case .stampBoard: return "스탬프판"
        case .profile: return "프로필"
        }
    }
}

enum MyPage {
    enum Tab {
        static let fontSize: CGFloat = 24
        static let textSpacing: CGFloat = 12
        static let leading: CGFloat = 16
    }
    
    enum User {
        static let editImage: String = "edit"
        static let editImageSize: CGFloat = 18
        static let profileImageSize: CGFloat = 70
        static let fontSizeSmall: CGFloat = 14
        static let fontSizeMedium: CGFloat = 20
        static let contentVSpacing: CGFloat = 7
        static let contentHSpacing: CGFloat = 8
        static let top: CGFloat = 12
    }
    
    enum Menu {
        static let fontSizeMedium: CGFloat = 16
        static let fontSizeSmall: CGFloat = 14
        static let dividerHeight: CGFloat = 1
    }
    
    enum TableView {
        static let sectionHeight: CGFloat = 45
        static let cellHeight: CGFloat = 58
    }
}
