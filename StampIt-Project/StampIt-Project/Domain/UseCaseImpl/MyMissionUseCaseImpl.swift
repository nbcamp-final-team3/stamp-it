//
//  MyMissionUseCaseImpl.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation
import RxSwift

final class MyMissionUseCaseImpl: MyMissionUseCaseProtocol {
    let homeRepository: HomeRepositoryProtocol
    let expirationService: MissionExpirationService

    init(homeRepository: HomeRepositoryProtocol, expirationService: MissionExpirationService) {
        self.homeRepository = homeRepository
        self.expirationService = expirationService
    }

    func fetchMissions(to userID: String?, ofGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchMissions(to: userID, by: nil, ofGroup: groupID)
            .do { [weak self] missions in
                self?.expirationService.handleExpiredMissions(missions, groupID: groupID)
            }
            .map { $0.sorted { $0.createDate > $1.createDate } }
    }

    func fetchAssignedMissions(to userID: String?, ofGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchMissions(to: userID, by: nil, ofGroup: groupID)
            .do { [weak self] missions in
                self?.expirationService.handleExpiredMissions(missions, groupID: groupID)
            }
            .map { $0
                .sorted { $0.createDate > $1.createDate }
                .filter { $0.status == .assigned && $0.dueDate.isWithinNext(days: 6) }
            }
    }

    func updateMissionStatus(for mission: Mission, ofGroup groupID: String, to status: MissionStatus) -> Observable<Mission> {
        homeRepository.updateMissionStatus(for: mission, ofGroup: groupID, to: status)
    }

    func createStamp(user: User, mission: Mission) -> Observable<Void> {
        homeRepository.createStamp(
            userId: user.userID,
            groupId: user.groupID,
            missionTitle: mission.title,
            maxStamp: Stamp.totalStamp,
            stampType: StampType.red.rawValue,
            missionId: mission.missionID,
            assignedBy: mission.assignedBy
        )
    }

    func deleteStamp(missionID: String) -> Observable<Void> {
        homeRepository.deleteStamp(missionID: missionID)
    }
}
