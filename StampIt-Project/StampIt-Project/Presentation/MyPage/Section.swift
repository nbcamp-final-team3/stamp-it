//
//  ProfileSection.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

enum MyPageProfileSection: Int, CaseIterable {
    case groupMember
    case groupService
    
    var title: String {
        switch self {
        case .groupMember: return "그룹 구성원 관리"
        case .groupService: return "그룹 및 서비스 관리"
        }
    }
    
    var contents: [(String, String)] {
        switch self {
        case .groupMember:
            return [
                ("멤버 삭제하기", ""),
                ("초대 하기", "그룹에 새로운 구성원 초대하기"),
                ("초대 받기", "새로운 그룹에 초대받기"),
            ]
        case .groupService:
            return [
                ("그룹 탈퇴", "‘그룹명' 그룹에서 탈퇴하기"),
                ("서비스 탈퇴", "‘스탬프잇' 탈퇴하기")
            ]
        }
    }
}
