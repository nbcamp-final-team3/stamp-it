//
//  HomeUseCaseImpl.swift
//  StampIt-Project
//
//  Created by daeun on 6/13/25.
//

import Foundation
import RxSwift

final class HomeUseCase: HomeUseCaseProtocol {
    let authRepository: AuthRepositoryProtocol
    let homeRepository: HomeRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol, homeRepository: HomeRepositoryProtocol) {
        self.authRepository = authRepository
        self.homeRepository = homeRepository
    }

    func fetchCurrentUser() -> Observable<User?> {
        authRepository.getCurrentUser()
    }
	
    func fetchRanking(ofGroup groupID: String) -> Observable<[User]> {
        homeRepository.fetchGroupMembers(ofGroup: groupID)
            .map { users in
                // TODO: 멤버들이 가진 월별 스티커 수로 sort
                return users
            }
    }
    func fetchRecievedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchRecievedMissions(ofUser: userID, fromGroup: groupID)
            .map { missions in
                let startOfToday = Calendar.current.startOfDay(for: Date())
                guard let endDate = Calendar.current.date(
                    byAdding: .day,
                    value: 6,
                    to: startOfToday
                ) else {
                    return []
                }
                return missions
                    .filter { startOfToday...endDate ~= $0.dueDate && $0.status == .assigned }
                    .sorted { $0.createDate > $1.createDate }
            }
    }
    func fetchSendedMissions(ofUser userID: String) -> Observable<[Mission]> {
        .empty()
    }
    func updateMissionStatus(for missionID: String, to status: MissionStatus) {
    }
}
