//
//  User.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/5/25.
//

import Foundation

struct User {
    let userID: String
    let nickname: String
    let profileImage: String?
    let boards: [StampBoard]
    let groupID: String         // 현재 활성 그룹 ID
    let groupName: String       // 현재 활성 그룹 이름
    let isLeader: Bool          // 현재 그룹에서의 리더 여부
    let joinedGroupAt: Date     // 현재 그룹 가입일
}
