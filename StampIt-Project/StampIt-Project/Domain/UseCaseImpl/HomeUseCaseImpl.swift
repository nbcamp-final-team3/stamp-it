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
            .flatMapLatest { [weak self] missions -> Observable<[Mission]> in
                guard let self else { return .empty() }
                let startOfToday = Calendar.current.startOfDay(for: Date())
                guard let endDate = Calendar.current.date(
                    byAdding: .day,
                    value: 6,
                    to: startOfToday
                ) else { return .empty() }

                return handleExpiredAndMerge(missions: missions, groupID: groupID)
                    .map {
                        $0.filter { startOfToday...endDate ~= $0.dueDate && $0.status == .assigned }
                          .sorted { $0.createDate > $1.createDate }
                    }
            }
    }

    func fetchSendedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]> {
        homeRepository.fetchMissions(to: nil, by: userID, ofGroup: groupID)
            .flatMapLatest { [weak self] missions -> Observable<[Mission]> in
                guard let self else { return .empty() }
                return handleExpiredAndMerge(missions: missions, groupID: groupID)
            }
    }

    func updateMissionStatus(for mission: Mission, ofGroup groupID: String, to status: MissionStatus) -> Observable<Mission> {
        homeRepository.updateMissionStatus(for: mission, ofGroup: groupID, to: status)
    }

    func createSticker(
        userId: String,
        groupId: String,
        missionTitle: String,
        assignedBy: String,
        stickerType: String
    ) -> Observable<Void> {
        homeRepository.createSticker(
            userId: userId,
            groupId: groupId,
            missionTitle: missionTitle,
            assignedBy: assignedBy,
            stickerType: stickerType,
        )
    }

    /// 만료된 assigned 미션을 서버에 failed로 업데이트하고
    /// 나머지 미션과 합쳐서 생성일 순으로 내림차순 정렬된 배열을 방출
    private func handleExpiredAndMerge(missions: [Mission], groupID: String) -> Observable<[Mission]> {
        let toExpire = missions.filter { $0.status == .assigned && $0.dueDate < Date() }
        let others = missions.filter { !toExpire.contains($0) }

        return Observable
            .from(toExpire)
            .concatMap { mission in
                self.updateMissionStatus(for: mission, ofGroup: groupID, to: .failed)
            }
            .toArray()
            .asObservable()
            .map { updated in
                (others + updated).sorted { $0.createDate > $1.createDate }
            }
    }
}
