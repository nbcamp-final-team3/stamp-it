//
//  ProfileSection.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

enum MyPageProfileSection: CaseIterable {
    case groupMember
    case groupService
    
    var menus: [MyPageMenu] {
        switch self {
        case .groupMember:
            return [.deleteMember, .inviteMember, .receiveInvite]
        case .groupService:
            return [.leaveGroup, .leaveService]
        }
    }
    
    var headerTitle: String {
        switch self {
        case .groupMember: return "그룹 구성원 관리"
        case .groupService: return "그룹 및 서비스 관리"
        }
    }
}

enum MyPageMenu: CaseIterable {
    case deleteMember
    case inviteMember
    case receiveInvite
    case leaveGroup
    case leaveService
    
    var title: String {
        switch self {
        case .deleteMember: return "멤버 삭제하기"
        case .inviteMember: return "초대 하기"
        case .receiveInvite: return "초대 받기"
        case .leaveGroup: return "그룹 탈퇴"
        case .leaveService: return "서비스 탈퇴"
        }
    }
    
    var subtitle: String {
        switch self {
        case .deleteMember: return ""
        case .inviteMember: return "그룹에 새로운 구성원 초대하기"
        case .receiveInvite: return "새로운 그룹에 초대받기"
        case .leaveGroup: return "‘그룹명' 그룹에서 탈퇴하기"
        case .leaveService: return "‘스탬프잇' 탈퇴하기"
        }
    }
}
