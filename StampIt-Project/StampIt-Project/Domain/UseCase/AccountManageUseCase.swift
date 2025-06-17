//
//  AccountManageUseCase.swift
//  StampIt-Project
//
//  Created by iOS study on 6/17/25.
//

import Foundation
import RxSwift

/// 로그아웃, 계정탈퇴, 그룹탈퇴, 현재 사용자 정보 조회
protocol AccountManageUseCaseProtocol {
    func signOut() -> Observable<Void>
    func deleteAccount() -> Observable<Void>
    func leaveGroup() -> Observable<User>
    func getCurrentUser() -> Observable<User?>
    func getGroupMemberCount(groupId: String) -> Observable<Int>
}
