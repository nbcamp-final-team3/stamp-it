//
//  HomeRepositoryImpl.swift
//  StampIt-Project
//
//  Created by daeun on 6/13/25.
//

import Foundation
import RxSwift

final class HomeRepository: HomeRepositoryProtocol {
    private let manager: FirestoreManagerProtocol

    init(manager: FirestoreManagerProtocol) {
        self.manager = manager
    }

    func fetchGroupMembers(ofGroup groupID: String) -> Observable<[User]> {
        manager.fetchMembers(groupId: groupID)
            .flatMapLatest { [weak self] members -> Observable<[User]> in
                guard let self else { return .just([]) }
                let userObservables = members.map { member in
                    self.manager.fetchUser(userId: member.userId)
                        .map { $0.toDomainModel() }
                }
                return Observable.zip(userObservables)
            }
    }

    func fetchRecievedMissions(ofUser userID: String) -> Observable<[Mission]> {
        .empty()
    }

    func fetchSendedMissions(ofUser userID: String) -> Observable<[Mission]> {
        .empty()
    }

    func updateMissionStatus(for missionID: String, to status: MissionStatus) {
        
    }
}
