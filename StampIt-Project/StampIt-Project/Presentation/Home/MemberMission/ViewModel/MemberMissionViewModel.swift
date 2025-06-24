//
//  MemberMissionViewModel.swift
//  StampIt-Project
//
//  Created by daeun on 6/17/25.
//

import Foundation
import RxSwift
import RxRelay

final class MemberMissionViewModel: ViewModelProtocol {
    // MARK: - Dependency

    private let useCase: MemberMissionUseCaseProtocol

    // MARK: - Action & State

    enum Action {
        case viewDidLoad
        case didTapBackButton
        case didTapSendMission
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let missions = BehaviorRelay<[MemberMissionItem]>(value: [])
        let isPopVC = PublishRelay<Void>()
        let isMoveToMissionTap = PublishRelay<Void>()
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    private var memberCache: [String: Member] = [:]

    // MARK: - Init

    init(user: User, memberCache: [String: Member], useCase: MemberMissionUseCaseProtocol) {
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
                    owner.fetchMissions()
                case .didTapSendMission:
                    owner.state.isMoveToMissionTap.accept(())
                case .didTapBackButton:
                    owner.state.isPopVC.accept(())
                }
            }
            .disposed(by: disposeBag)
    }

    /// 유저가 그룹 구성원에게 할당한 미션 바인딩
    private func fetchMissions() {
        guard let user = state.user.value else { return }
        useCase.fetchMissions(by: user.userID, ofGroup: user.groupID)
            .map { [weak self] in
                guard let self else { return [] }
                return mapMissionsToMemberMissionItems($0)
            }
            .bind(to: state.missions)
            .disposed(by: disposeBag)
    }

    // MARK: - Methods

    private func mapMissionsToMemberMissionItems(_ missions: [Mission]) -> [MemberMissionItem] {
        missions.map { mission in
            let assignee = memberCache[mission.assignedTo]?.nickname ?? mission.assignedTo
            let (isOverdue, daysLeft) = formatOverdueAndDays(from: mission.dueDate)
            let missionItem = HomeMemberMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assignee: assignee,
                status: mission.status,
                isOverdue: isOverdue,
                daysLeft: daysLeft
            )
            return MemberMissionItem.mission(missionItem)
        }
    }

    private func isNew(createDate: Date) -> Bool {
        let today = Calendar.current.dateComponents([.day], from: Date())
        let created = Calendar.current.dateComponents([.day], from: createDate)
        return today.day == created.day
    }

    private func formatOverdueAndDays(from dueDate: Date) -> (isOverdue: Bool, daysLeft: String) {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let dueStart = cal.startOfDay(for: dueDate)

        let dayDiff = cal.dateComponents([.day], from: todayStart, to: dueStart).day ?? 0

        let isOverdue = dayDiff < 0
        let daysLeft = dayDiff == 0 ? "오늘" : "\(dayDiff)일 전"

        return (isOverdue, daysLeft)
    }
}
