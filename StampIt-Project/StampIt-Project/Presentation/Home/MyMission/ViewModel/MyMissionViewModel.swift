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
        case didTapStatusButton(id: String)
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let missions = BehaviorRelay<[MyMissionItem]>(value: [])
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    private var memberCache: [String: User] = [:]
    private var receivedMissions = [Mission]()
    private var pendingCommits = DisposeBag()

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
                case .didTapStatusButton(let id):
                    owner.handleMissionCompleteButtonTapped(missionID: id)
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

    /// 미션 완료 바인딩
    ///
    /// 전달받은 미션의 ID로 receivedMissions에서 해당 미션을 찾아 UI를 우선 업데이트,
    /// 4초간 대기 후 캐시 업데이트 및 API 호출
    func handleMissionCompleteButtonTapped(missionID: String) {
        updateMissionItem(missionID: missionID)

        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.pendingCommits = DisposeBag()
        }
        #endif

        // cancelMissionComplete() 호출 시 dispose되는 Observable
        Observable<Void>.just(())
            .delay(.seconds(4), scheduler: MainScheduler.instance)
            .subscribe(with: self) { owner, _ in
                let removedMission = owner.updateMissionCache(missionID: missionID)
                guard let mission = removedMission,
                      let user = owner.state.user.value else { return }
                _ = owner.useCase
                    .updateMissionStatus(for: mission, ofGroup: user.groupID, to: .completed)
                    .subscribe()
                    .disposed(by: owner.disposeBag)
            }
            .disposed(by: pendingCommits)
    }

    /// UI에서 미션 업데이트
    private func updateMissionItem(missionID: String) {
        let items = state.missions.value
        let updated = items.map { item in
            let mission = item.mission!
            if mission.missionID == missionID {
                let updated = HomeReceivedMission(
                    missionID: mission.missionID,
                    title: mission.title,
                    category: mission.category,
                    dueDate: mission.dueDate,
                    assigner: mission.assigner,
                    isNew: mission.isNew,
                    isOverdue: mission.isOverdue,
                    status: .completed
                )
                return MyMissionItem.mission(updated)
            }
            return item
        }
        state.missions.accept(updated)
    }

    /// 도메인 미션 캐시에서 미션 업데이트
    private func updateMissionCache(missionID: String) -> Mission? {
        guard let index = receivedMissions.firstIndex(where: { $0.missionID == missionID }) else { return nil }
        let missionToUpdate = receivedMissions[index]
        let updated = Mission(
            missionID: missionToUpdate.missionID,
            title: missionToUpdate.missionID,
            assignedTo: missionToUpdate.assignedTo,
            assignedBy: missionToUpdate.assignedBy,
            createDate: missionToUpdate.createDate,
            dueDate: missionToUpdate.dueDate,
            status: .completed,
            imageURL: missionToUpdate.imageURL,
            category: missionToUpdate.category
        )
        receivedMissions[index] = updated
        return updated
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
