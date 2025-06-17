//
//  MemberMissionUseCase.swift
//  StampIt-Project
//
//  Created by daeun on 6/17/25.
//

import Foundation
import RxSwift

final class MemberMissionUseCase: MemberMissionUseCaseProtocol {
    let homeRepository: HomeRepositoryProtocol

    init(homeRepository: HomeRepositoryProtocol) {
        self.homeRepository = homeRepository
    }

    func fetchSendedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchMissions(to: nil, by: userID, ofGroup: groupID)
            .map { missions in
                missions.sorted { $0.createDate > $1.createDate }
            }
    }
}
