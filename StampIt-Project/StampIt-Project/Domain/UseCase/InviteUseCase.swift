//
//  Invite.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift

protocol InviteUseCase {
    //receive 관련 메서드
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void>
    //send 관련 메서드
    // 아직 없음
    // 공통 메서드
    func getCurrentUser() -> Observable<StampIt_Project.User?>
}
