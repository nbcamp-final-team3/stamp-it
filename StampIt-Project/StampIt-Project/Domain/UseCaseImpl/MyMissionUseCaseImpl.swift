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

    func fetchMissions(to userID: String?, ofGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchMissions(to: userID, by: nil, ofGroup: groupID)
            .do { [weak self] missions in
                self?.handleExpiredMissions(missions, groupID: groupID)
            }
            .map { $0.sorted { $0.createDate > $1.createDate } }
    }

    private func handleExpiredMissions(_ missions: [Mission], groupID: String) {
        let toExpire = getExpiredMissions(missions)
        toExpire.forEach { mission in
            _ = self.homeRepository
                .updateMissionStatus(for: mission, ofGroup: groupID, to: .failed)
                .take(1)
                .subscribe()
        }
    }

    private func getExpiredMissions(_ missions: [Mission]) -> [Mission] {
        return missions.filter {
            let dueDay = Calendar.current.component(.day, from: $0.dueDate)
            let today = Calendar.current.component(.day, from: Date())
            return $0.status == .assigned && dueDay < today
        }
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
