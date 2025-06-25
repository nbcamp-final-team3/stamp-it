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
            let dueDay = Calendar.current.component(.day, from: $0.dueDate)
            let today = Calendar.current.component(.day, from: Date())
            return $0.status == .assigned && dueDay < today
        }
    }
}
