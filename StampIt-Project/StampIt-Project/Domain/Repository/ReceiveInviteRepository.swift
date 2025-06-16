//
//  InviteRepository.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/16/25.
//

import Foundation
import RxSwift

protocol ReceiveInviteRepository {
    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore>
    func fetchUserOnce(userId: String) -> Observable<UserFirestore>
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void>
}
