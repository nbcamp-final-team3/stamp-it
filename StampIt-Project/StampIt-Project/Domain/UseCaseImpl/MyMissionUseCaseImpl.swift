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

    func updateMissionStatus(for mission: Mission, ofGroup groupID: String, to status: MissionStatus) -> Observable<Mission> {
        homeRepository.updateMissionStatus(for: mission, ofGroup: groupID, to: status)
    }

    func createSticker(
        userId: String,
        groupId: String,
        missionTitle: String,
        maxSticker: Int,
        stickerType: String,
        assignedBy: String
    ) -> Observable<Void> {
        homeRepository.createSticker(
            userId: userId,
            groupId: groupId,
            missionTitle: missionTitle,
            maxSticker: maxSticker,
            stickerType: stickerType,
            assignedBy: assignedBy
        )
    }
}
