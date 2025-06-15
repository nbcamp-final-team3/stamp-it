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
    func fetchRecievedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchRecievedMissions(ofUser: userID, fromGroup: groupID)
            .map { missions in
                // TODO: 상태가 aasigned인 미션 중 마감일이 오늘 + 앞으로 6일까지의 미션만 노출, 정렬은 최신순
                // 현재는 manager에서 필터링하여 주고 있는데, 날짜에 대한 필터링은 유즈케이스에서 수행하는게 맞는 것 같아, 수정 예정
                missions.sorted { $0.createDate > $1.createDate }
            }
    }
    func fetchSendedMissions(ofUser userID: String) -> Observable<[Mission]> {
        .empty()
    }
    func updateMissionStatus(for missionID: String, to status: MissionStatus) {
    }
}
