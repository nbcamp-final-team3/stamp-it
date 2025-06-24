//
//  MemberMissionUseCase.swift
//  StampIt-Project
//
//  Created by daeun on 6/17/25.
//

import Foundation
import RxSwift

final class MemberMissionUseCaseImpl: MemberMissionUseCaseProtocol {
    let homeRepository: HomeRepositoryProtocol

    init(homeRepository: HomeRepositoryProtocol) {
        self.homeRepository = homeRepository
    }

    func fetchMissions(by userID: String, ofGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchMissions(to: nil, by: userID, ofGroup: groupID)
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
}
