//
//  HomeRepositoryImpl.swift
//  StampIt-Project
//
//  Created by daeun on 6/13/25.
//

import Foundation
import RxSwift
import FirebaseFirestore

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

    func fetchMissions(
        to assigneeID: String?,
        by assignerID: String?,
        ofGroup groupID: String
    ) -> Observable<[Mission]> {
        manager.fetchMissions(to: assigneeID, by: assignerID, ofGroup: groupID)
            .map { $0.map { $0.toDomainModel() } }
    }
    
    func updateMissionStatus(for mission: Mission, ofGroup groupID: String, to status: MissionStatus) -> Observable<Void> {
        let updated = MissionFirestore(
            missionId: mission.missionID,
            title: mission.title,
            assignedBy: mission.assignedBy,
            assignedTo: mission.assignedTo,
            createDate: Timestamp(date: mission.createDate),
            dueDate: Timestamp(date: mission.dueDate),
            category: mission.category.rawValue,
            status: status.rawValue,
            // TODO: 커스텀 타입 추가 시 도메인 모델 변경
            missionType: MissionFirestore.MissionType.app.rawValue,
            createdAt: Timestamp(date: mission.createDate)
        )

        return manager.updateMission(groupId: groupID, mission: updated)
    }
}
