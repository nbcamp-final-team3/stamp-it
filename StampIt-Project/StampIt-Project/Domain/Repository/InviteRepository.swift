//
//  InviteRepository.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift

protocol InviteRepository {
    // receive 관련 메서드
    func fetchInvite(inviteCode: String) -> Observable<InviteFirestore>
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void>
    func updateUser(_ user: UserFirestore) -> Observable<Void>
    // send 관련 메서드
    func createInvite(_ invite: InviteFirestore) -> Observable<Void>
    func fetchGroup(groupId: String) -> Observable<GroupFirestore>
    // 공통 메서드
    func fetchUserOnce(userId: String) -> Observable<UserFirestore>
    // 06/17 추가된 메서드
    /// 초대코드로 그룹 정보 가져오기
    func fetchGroupByInviteCode(inviteCode: String) -> Observable<GroupFirestore>
    /// 그룹의 멤버 수 확인
    func fetchGroupMemberCount(groupId: String) -> Observable<Int>
    // 초대받아서 성공 했을 경우에 가지고 있던 그룹 삭제 처리
    /// 그룹 삭제
    func deleteGroup(groupId: String) -> Observable<Void>
    // 이건 아직 잘 모르겠음
    func switchUserGroup(userId: String, fromGroupId: String, toGroupId: String, userNickname: String) -> Observable<Void>
}
