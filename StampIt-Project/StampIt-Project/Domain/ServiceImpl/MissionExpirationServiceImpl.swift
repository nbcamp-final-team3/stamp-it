//
//  MissionExpirationServiceImpl.swift
//  StampIt-Project
//
//  Created by daeun on 6/24/25.
//

import Foundation

final class MissionExpirationServiceImpl: MissionExpirationService {
    var homeRepository: HomeRepositoryProtocol

    init(homeRepository: HomeRepositoryProtocol) {
        self.homeRepository = homeRepository
    }

    func handleExpiredMissions(_ missions: [Mission], groupID: String) {
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
            let startOfToday = Calendar.current.startOfDay(for: Date())
            let startOfDueDate = Calendar.current.startOfDay(for: $0.dueDate)
            return $0.status == .assigned && startOfDueDate < startOfToday
        }
    }
}
