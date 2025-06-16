//
//  ReceiveInviteUseCase.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/13/25.
//

import Foundation
import RxSwift


protocol ReceiveInviteUseCase {
    func getCurrentUser() -> Observable<StampIt_Project.User?>
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void>
}
