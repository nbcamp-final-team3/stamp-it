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
    private let noticeRepository: NoticeRepositoryProtocol

    init(homeRepository: HomeRepositoryProtocol,
         authRepository: AuthRepositoryProtocol,
         expirationService: MissionExpirationService,
         noticeRepository: NoticeRepositoryProtocol,
    ) {
        self.homeRepository = homeRepository
        self.expirationService = expirationService
        self.user = authRepository.getCurrentUser()
            .replay(1)
            .refCount()
        self.noticeRepository = noticeRepository
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

    func createStamp(mission: Mission) -> Observable<Void> {
        user.flatMap { [weak self] user -> Observable<Void> in
            guard let self, let user else { return .empty() }
            return homeRepository.createStamp(
                userId: user.userID,
                groupId: user.groupID,
                missionTitle: mission.title,
                maxStamp: 30, // TODO: pin 번호 계산용
                stampType: StampType.stampRed.rawValue, // TODO: 스티커 타입 결정 로직 추가
                missionId: mission.missionID,
                assignedBy: mission.assignedBy
            )
        }
    }

    func deleteStamp(missionID: String) -> Observable<Void> {
        homeRepository.deleteStamp(missionID: missionID)
    }

    func requestMission() -> Observable<Void> {
        user.flatMap { [weak self] user -> Observable<(User, [Member])> in
            guard let self, let user else { return .empty() }
            return homeRepository.fetchGroupMembers(ofGroup: user.groupID)
                .map { (user, $0) }
        }
        .flatMap { [weak self] user, members -> Observable<Void> in
            guard let self else { return .empty() }
            let notice = Notice(
                noticeId: UUID().uuidString,
                title: "미션 조르기",
                description: "\(user.nickname)님으로부터 미션 조르기 알림이 도착했어요! \(user.nickname)님에게 미션을 주러 가볼까요?",
                category: .missionRequest,
                createdAt: Date(),
                isRead: false
            )
            let noticeObservables = members.filter { $0.userID != user.userID }.map {
                self.noticeRepository.createNotice(notice, receiverId: $0.userID)
            }
            return Observable.zip(noticeObservables).map { _ in () }
        }
    }
}
