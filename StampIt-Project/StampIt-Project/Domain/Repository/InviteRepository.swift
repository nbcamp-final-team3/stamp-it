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
    func fetchInvite(inviteCode: String) -> Observable<Invite>
    func addMember(groupId: String, member: Member) -> Observable<Void>
    // send 관련 메서드
    func createInvite(_ invite: Invite) -> Observable<Void>
    func fetchGroup(groupId: String) -> Observable<Group>
    // 공통 메서드
    func fetchUserOnce(userId: String) -> Observable<User>
    // 06/17 추가된 메서드
    /// 초대코드로 그룹 정보 가져오기
    func fetchGroupByInviteCode(inviteCode: String) -> Observable<Group>
    /// 그룹의 멤버 수 확인
    func fetchGroupMemberCount(groupId: String) -> Observable<Int>
    // 초대받아서 성공 했을 경우에 가지고 있던 그룹 삭제 처리
    /// 그룹 삭제
    func deleteGroup(groupId: String) -> Observable<Void>
    
    func switchUserGroup(userId: String, fromGroupId: String, toGroupId: String, userNickname: String, profileImage: String) -> Observable<Void>

    // TODO: 사용자 데이터 정리 (재시도 로직 포함)
    // 📄 참고: Notion 육남매 대피소 > 유저 그룹 이동 시 시나리오 문서화
    func cleanupUserDataWithRetry(userId: String, currentGroupId: String, maxRetries: Int) -> Observable<Void>

}
