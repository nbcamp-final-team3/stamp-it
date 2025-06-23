//
//  Invite.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift

protocol InviteUseCase {
    /// 초대 코드 확인 메서드
    func acceptInvite(inviteCode: String) -> Observable<Invitation>
    /// 초대코드 생성 메서드
    func getInviteCode() -> Observable<String>
}
