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
    let expirationService: MissionExpirationService

    init(homeRepository: HomeRepositoryProtocol, expirationService: MissionExpirationService) {
        self.homeRepository = homeRepository
        self.expirationService = expirationService
    }

    func fetchMissions(by userID: String, ofGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchMissions(to: nil, by: userID, ofGroup: groupID)
            .do { [weak self] missions in
                self?.expirationService.handleExpiredMissions(missions, groupID: groupID)
            }
            .map { $0.sorted { $0.createDate > $1.createDate } }
    }
}
