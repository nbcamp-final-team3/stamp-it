//
//  ProfileSection.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

// MARK: - MyPage Profile Section

enum MyPageProfileSection: CaseIterable {
    case groupMember
    case groupService

    var menus: [MyPageMenu] {
        switch self {
        case .groupMember:
            return [.MemberManage, .inviteMember, .receiveInvite]
        case .groupService:
            return [.leaveGroup, .logout, .leaveService]
        }
    }
    
    var headerTitle: String {
        switch self {
        case .groupMember: return "그룹 구성원 관리"
        case .groupService: return "그룹 및 서비스 관리"
        }
    }
}

// MARK: - MyPage Menu

enum MyPageMenu: CaseIterable {
    case MemberManage
    case inviteMember
    case receiveInvite
    case leaveGroup
    case logout
    case leaveService
    
    var title: String {
        switch self {
        case .MemberManage: return "멤버 관리"
        case .inviteMember: return "초대 하기"
        case .receiveInvite: return "초대 받기"
        case .leaveGroup: return "그룹 탈퇴"
        case .logout: return "로그아웃"
        case .leaveService: return "서비스 탈퇴"
        }
    }
    
    var subtitle: String {
        switch self {
        case .MemberManage: return "그룹 멤버 관리하기"
        case .inviteMember: return "그룹에 새로운 구성원 초대하기"
        case .receiveInvite: return "새로운 그룹에 초대받기"
        case .leaveGroup: return "현재 그룹에서 탈퇴하기"
        case .logout: return "현재 계정 로그아웃하기"
        case .leaveService: return "‘스탬프잇' 탈퇴하기"
        }
    }
}

// MARK: - StampBoard Section

enum StampBoardSection: Int, Hashable, CaseIterable {
    case summary
    case page
    
    var type: [[StampCellType]] {
        switch self {
        case .page:
            return [
                [.horizontal, .horizontal, .horizontal, .horizontal, .vertical],
                [.both, .horizontal, .horizontal, .horizontal, .none],
                [.horizontal, .horizontal, .horizontal, .horizontal, .vertical],
                [.both, .horizontal, .horizontal, .horizontal, .none],
                [.horizontal, .horizontal, .horizontal, .horizontal, .vertical],
                [.horizontal, .horizontal, .horizontal, .horizontal, .none],
            ]
        default: return .init()
        }
    }
    
    static var column: Int { 5 }
    
    static var totalStamp: Int { 30 }
}

// MARK: - StampBoard Item

enum StampBoardItem: Hashable {
    case summary(collected: Int, completed: Int)
    case sticker(StickerUI)
}


// MARK: - Stamp Cell Type

/// Dashed Line 방향 기준
enum StampCellType: Hashable {
    case horizontal
    case vertical
    case both
    case none
}
