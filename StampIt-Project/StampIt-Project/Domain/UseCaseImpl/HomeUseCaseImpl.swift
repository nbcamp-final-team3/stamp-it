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

    func fetchUser() -> Observable<User?> {
        authRepository.getCurrentUser()
    }
    func fetchRanking(ofGroup groupID: String) -> Observable<[User]> {
        homeRepository.fetchGroupMembers(ofGroup: groupID)
            .map { users in
                // TODO: 멤버들이 가진 월별 스티커 수로 sort
                return users
            }
    }
    func fetchRecievedMissions(ofUser userID: String) -> Observable<[Mission]> {
        .empty()
    }
    func fetchSendedMissions(ofUser userID: String) -> Observable<[Mission]> {
        .empty()
    }
    func updateMissionStatus(for missionID: String, to status: MissionStatus) {
    }
}
