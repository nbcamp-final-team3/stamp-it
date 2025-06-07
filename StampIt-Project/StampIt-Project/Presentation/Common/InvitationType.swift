//
//  InvitationType.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/7/25.
//

import Foundation

enum InvitationType {
    case send
    case receive

    var title: String {
        switch self {
        case .send:
            "초대하기"
        case .receive:
            "초대받기"
        }
    }

    var description: String {
        switch self {
        case .send:
            "내 그룹에 새로운 구성원 초대하기"
        case .receive:
            "새로운 그룹에 초대받기"
        }
    }
}
