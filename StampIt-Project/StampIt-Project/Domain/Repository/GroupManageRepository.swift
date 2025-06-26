//
//  GroupManageRepository.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/26/25.
//

import Foundation
import RxSwift

protocol GroupManageRepository {
    /// 리더 위임
    func delegateLeader(to memberId: String, groupId: String) -> Observable<Void>
    
    /// 그룹 멤버 목록 가져오기
    func fetchGroupMembers(groupId: String) -> Observable<[Member]>
}
