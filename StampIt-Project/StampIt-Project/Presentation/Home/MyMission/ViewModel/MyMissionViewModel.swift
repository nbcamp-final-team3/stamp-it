//
//  MyMissionViewModel.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation
import RxSwift
import RxRelay

final class MyMissionViewModel {
    // MARK: - Dependency

    private let useCase: MyMissionUseCaseProtocol

    // MARK: - Action & State

    enum Action {
        case viewDidLoad
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let missions = BehaviorRelay<[MyMissionItem]>(value: [])
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    var memberCache: [String: User] = [:]

    // MARK: - Init

    init(user: User, memberCache: [String: User], useCase: MyMissionUseCaseProtocol) {
        self.useCase = useCase
        state.user.accept(user)
        self.memberCache = memberCache
        bind()
    }

    // MARK: - Bind

    private func bind() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .viewDidLoad:
                    guard let user = owner.state.user.value else { return }
                    owner.useCase.fetchReceivedMissions(ofUser: user.userID, fromGroup: user.groupID)
                        .map { owner.mapMissionsToMyMissionItems($0) }
                        .bind(to: owner.state.missions)
                        .disposed(by: owner.disposeBag)
                }
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Methods

    private func mapMissionsToMyMissionItems(_ missions: [Mission]) -> [MyMissionItem] {
        missions.map { mission in
            let assigner = memberCache[mission.assignedBy]?.nickname ?? mission.assignedBy
            let missionItem = HomeReceivedMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assigner: assigner,
                isNew: isNew(createDate: mission.createDate),
                isOverdue: formatOverdue(from: mission.dueDate),
                status: mission.status
            )
            return MyMissionItem.mission(missionItem)
        }
    }

    private func isNew(createDate: Date) -> Bool {
        let today = Calendar.current.dateComponents([.day], from: Date())
        let created = Calendar.current.dateComponents([.day], from: createDate)
        return today.day == created.day
    }

    private func formatOverdue(from dueDate: Date) -> Bool {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let dueStart = cal.startOfDay(for: dueDate)
        let dayDiff = cal.dateComponents([.day], from: todayStart, to: dueStart).day ?? 0
        return dayDiff < 0
    }
}
