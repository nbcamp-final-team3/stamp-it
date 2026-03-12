//
//  GroupManageUseCase.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/26/25.
//

import Foundation
import RxSwift

protocol GroupManageUseCaseProtocol {
    /// 리더 위임
    func delegateLeader(to memberId: String) -> Observable<Void>
    
    /// 멤버 내보내기
    func exportMember(member: User) -> Observable<User>
    
    /// 현재 사용자 정보 가져오기
    func getCurrentUser() -> Observable<User?>
    
    /// 그룹 멤버 목록 가져오기
    func fetchGroupMembers(groupId: String) -> Observable<[Member]>
    
    /// 그룹 간 이동 (현재 그룹 탈퇴 후 새 그룹 가입)
    func switchToNewGroup(inviteCode: String) -> Observable<Void>
    
    /// 그룹 멤버 관리 초기 데이터 로드
    func loadGroupMemberManageData() -> Observable<GroupMemberLoadModel>
    
    /// 멤버 ID로 멤버 내보내기
    func exportMember(memberId: String) -> Observable<Void>
    
    /// 멤버 목록 새로고침
    func refreshMembers() -> Observable<[Member]>

    /// 그룹 탈퇴
    func leaveGroup() -> Observable<User>

    /// 멤버 수 조회
    func getGroupMemberCount(groupId: String) -> Observable<Int>

}

