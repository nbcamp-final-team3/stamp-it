//
//  group12.swift
//  StampIt-Project
//
//  Created by 윤주형 on 7/2/25.
//

import Foundation

// MARK: - 그룹 멤버 로드 custom model
struct GroupMemberLoadModel {
    let currentUser: User
    let members: [Member]
    let isLeader: Bool
}
