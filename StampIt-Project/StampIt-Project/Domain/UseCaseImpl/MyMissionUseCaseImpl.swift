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

    init(homeRepository: HomeRepositoryProtocol) {
        self.homeRepository = homeRepository
    }

    func fetchReceivedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchMissions(to: userID, by: nil, ofGroup: groupID)
            .map { missions in
                missions.sorted { $0.createDate > $1.createDate }
            }
    }

    func updateMissionStatus(for mission: Mission, ofGroup groupID: String, to status: MissionStatus) -> Observable<Void> {
        homeRepository.updateMissionStatus(for: mission, ofGroup: groupID, to: status)
    }

    func createSticker(
        userId: String,
        groupId: String,
        missionTitle: String,
        assignedBy: String,
        stickerType: String
    ) -> Observable<Void> {
        homeRepository.createSticker(
            userId: userId,
            groupId: groupId,
            missionTitle: missionTitle,
            assignedBy: assignedBy,
            stickerType: stickerType,
        )
    }
}
