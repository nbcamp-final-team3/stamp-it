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

    // var description: String {
    //     switch self {
    //     case .leaderMandate:
    //         "다른 멤버에게 그룹 리더 권한을 위임합니다"
    //     case .exportMember:
    //         "해당 멤버를 그룹에서 내보냅니다"
    //     }
    // }
}
