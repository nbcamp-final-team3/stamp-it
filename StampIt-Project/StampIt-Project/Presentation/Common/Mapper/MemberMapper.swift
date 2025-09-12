//
//  MemberMapper.swift
//  StampIt-Project
//
//  Created by daeun on 6/24/25.
//

import Foundation

final class MemberMapper: MemberMapping {

    /// [Member]를 컬렉션뷰에서 사용하는 [HomeMember]으로 매핑
    func map(members: [Member], userID: String) -> [HomeMember] {
        return members.enumerated().map { index, member in
            let isUser = member.userID == userID
            let member = HomeMember(
                memberID: member.userID,
                nickname: isUser ? "나" : member.nickname,
                stampCount: "\(member.monthStamp)개",
                rank: index + 1,
                profileImage: member.profileImage
            )
            return member
        }
    }
}

