//
//  HomeRepository.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation
import RxSwift

protocol HomeRepository {
    func fetchUser() -> Observable<User>
    func fetchMembers(ofGroup groupID: String) -> Observable<[Member]>
    func fetchUsers(for userIDs: [String]) -> Observable<[User]>
    func fetchRecievedMissions(ofUser userID: String) -> Observable<[Mission]>
    func fetchSendedMissions(ofUser userID: String) -> Observable<[Mission]>
    func updateMissionStatus(to status: MissionStatus)
}
