//
//  SendInviteRepository.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import Foundation
import RxSwift

protocol SendInviteRepository {
    func fetchUserOnce(userId: String) -> Observable<UserFirestore>
    func createInvite(_ invite: InviteFirestore) -> Observable<Void>
    func fetchGroup(groupId: String) -> Observable<GroupFirestore>
    func getCurrentUser() -> Observable<StampIt_Project.User?>
    func sequenceCreateCode() -> Observable<String>
}
