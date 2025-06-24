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
	
    func fetchRanking(ofGroup groupID: String) -> Observable<[Member]> {
        homeRepository.fetchGroupMembers(ofGroup: groupID)
            .map { members in
                members.sorted { $0.monthSticker > $1.monthSticker }
            }
    }

    func fetchReceivedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchMissions(to: userID, by: nil, ofGroup: groupID)
            .do { [weak self] missions in
                guard let self else { return }
                let toExpire = getExpiredMissions(missions)
                toExpire.forEach { mission in
                    _ = self.homeRepository
                        .updateMissionStatus(for: mission, ofGroup: groupID, to: .failed)
                        .take(1)
                        .subscribe()
                }
            }
            .map { missions in
                let startOfToday = Calendar.current.startOfDay(for: Date())
                let endDate = Calendar.current.date(byAdding: .day, value: 6, to: startOfToday)!

                return missions
                    .filter { startOfToday...endDate ~= $0.dueDate }
                    .sorted { $0.createDate > $1.createDate }
            }
    }

    func fetchSendedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchMissions(to: nil, by: userID, ofGroup: groupID)
            .do { [weak self] missions in
                guard let self else { return }
                let toExpire = getExpiredMissions(missions)
                toExpire.forEach { mission in
                    _ = self.homeRepository
                        .updateMissionStatus(for: mission, ofGroup: groupID, to: .failed)
                        .take(1)
                        .subscribe()
                }
            }
            .map { $0.sorted { $0.createDate > $1.createDate } }
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

    /// 만료된 assigned 미션을 서버에 failed로 업데이트하고
    /// 나머지 미션과 합쳐서 생성일 순으로 내림차순 정렬된 배열을 방출
    private func getExpiredMissions(_ missions: [Mission]) -> [Mission] {
        return missions.filter {
            let dueDay = Calendar.current.component(.day, from: $0.dueDate)
            let today = Calendar.current.component(.day, from: Date())
            return $0.status == .assigned && dueDay < today
        }
    }
}
