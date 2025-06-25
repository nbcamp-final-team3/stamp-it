//
//  MemberManageOptionType.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/25/25.
//

import Foundation

import Foundation

enum MemberManageOptionType {
    case leaderMandate
    case exportMember

    var title: String {
        switch self {
        case .leaderMandate:
            "그룹 리더 위임하기"
        case .exportMember:
            "멤버 내보내기"
        }
    }
}
