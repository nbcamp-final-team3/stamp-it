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
    func acceptInvite(inviteCode: String) -> Observable<Invite>
    /// 초대 코드와 사용자 정보를 함께 가져오는 메서드
    func getInviteCodeAndUserInfo() -> Observable<(String, User)>
    /// 다인 그룹 입장 시 확인이 필요한지 확인하는 메서드
    func checkIfConfirmationNeeded(inviteCode: String) -> Observable<Bool>
}
