//
//  AccountManageRepository.swift
//  StampIt-Project
//
//  Created by iOS study on 6/24/25.
//

import Foundation
import RxSwift

protocol AccountManageRepositoryProtocol {
    func signOut() -> Observable<Void>
    func deleteAccount() -> Observable<Void>
    func getGroupMemberCount(groupId: String) -> Observable<Int>
    func leaveGroup() -> Observable<User>
    func exportMember(member: User) -> Observable<User>
}
