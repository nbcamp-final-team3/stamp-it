//
//  MyMissionUseCaseImpl.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation
import RxSwift

final class MyMissionUseCaseImpl: MyMissionUseCaseProtocol {
    private let homeRepository: HomeRepositoryProtocol
    private let expirationService: MissionExpirationService
    private let user: Observable<User?>

    init(homeRepository: HomeRepositoryProtocol,
         authRepository: AuthRepositoryProtocol,
         expirationService: MissionExpirationService,
    ) {
        self.homeRepository = homeRepository
        self.expirationService = expirationService
        self.user = authRepository.getCurrentUser()
            .replay(1)
            .refCount()
    }
    
    // TODO: 도메인 mission 리팩토링 후 삭제 - assignedTo, assignedBy 닉네임 매핑
    func fetchGroupMembers() -> Observable<[String: Member]> {
        guard let user = UserCache.shared.getCurrentUser() else { return .empty() }
        return homeRepository.fetchGroupMembers(ofGroup: user.groupID)
            .map { Dictionary(uniqueKeysWithValues: $0.map { ($0.userID, $0) }) }
    }

    func fetchMissions() -> Observable<[Mission]> {
        user.flatMap { [weak self] user -> Observable<[Mission]> in
                guard let self, let user else { return .empty() }
                return homeRepository.fetchMissions(to: user.userID, by: nil, ofGroup: user.groupID)
                .do { [weak self] missions in
                    self?.expirationService.handleExpiredMissions(missions, groupID: user.groupID)
                }
            }
            .map { $0.sorted { $0.createDate > $1.createDate } }
    }

    func fetchAssignedMissions() -> Observable<[Mission]> {
        user.flatMap { [weak self] user -> Observable<[Mission]> in
                guard let self, let user else { return .empty() }
                return homeRepository.fetchMissions(to: user.userID, by: nil, ofGroup: user.groupID)
                .do { [weak self] missions in
                    self?.expirationService.handleExpiredMissions(missions, groupID: user.groupID)
                }
            }
            .map {
                $0.sorted { $0.createDate > $1.createDate }
                    .filter { $0.status == .assigned && $0.dueDate.isWithinNext(days: 6) }
            }
    }

    func updateMissionStatus(for mission: Mission, to status: MissionStatus) -> Observable<Mission> {
        user.flatMap { [weak self] user -> Observable<Mission> in
            guard let self, let user else { return .empty() }
            return homeRepository.updateMissionStatus(for: mission, ofGroup: user.groupID, to: status)
            }
    }

    func createSticker(mission: Mission) -> Observable<Void> {
        user.flatMap { [weak self] user -> Observable<Void> in
            guard let self, let user else { return .empty() }
            return homeRepository.createSticker(
                userId: user.userID,
                groupId: user.groupID,
                missionTitle: mission.title,
                maxSticker: 30, // TODO: pin 번호 계산용
                stickerType: StickerType.stampRed.rawValue, // TODO: 스티커 타입 결정 로직 추가
                missionId: mission.missionID,
                assignedBy: mission.assignedBy
            )
        }
    }

    func deleteSticker(missionID: String) -> Observable<Void> {
        homeRepository.deleteSticker(missionID: missionID)
    }
}
