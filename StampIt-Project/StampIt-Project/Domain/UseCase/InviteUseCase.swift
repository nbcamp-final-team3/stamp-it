//
//  Invite.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift

protocol InviteUseCase {
    /// 현재 사용자 정보 조회
    func getCurrentUser() -> Observable<User?>
    /// 초대 코드 확인 메서드 - 사용자 정보와 초대 정보를 함께 반환
    func acceptInvite(inviteCode: String) -> Observable<(User, Invite)>
    /// 초대코드 생성 메서드
    func getInviteCode() -> Observable<String>
    /// 다인 그룹 입장 시 확인이 필요한지 확인하는 메서드
    func checkIfConfirmationNeeded(inviteCode: String) -> Observable<Bool>
}
