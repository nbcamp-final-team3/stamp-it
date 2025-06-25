//
//  Invite.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/5/25.
//

import Foundation

struct Invite {                 //Invitaion > Invite로 수정
    let inviteCode: String
    let groupId: String
    let groupName: String           // 추가
    let invitedBy: String           // createdBy → invitedBy로 통일 (초대한 사람)
    let createdAt: Date
}
