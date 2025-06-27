//
//  MyMissionViewModel.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation
import RxSwift
import RxRelay

final class MyMissionViewModel: ViewModelProtocol {
    // MARK: - Dependency

    private let useCase: MyMissionUseCaseProtocol
    private let mapper: MissionMapping

    // MARK: - Action & State

    enum Action {
        case viewDidLoad
        case selectFilter(Int)
        case didTapStatusButton(MyMissionItem)
        case didTapCompleteCancelButton
        case didTapBackButton
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let missionFilters = BehaviorRelay<[MyMissionItem]>(value: [])
        let filteredMissions = BehaviorRelay<[MyMissionItem]>(value: [])
        let selectedFilter = BehaviorRelay<Int>(value: 0)
        let completedMissionTitle = BehaviorRelay<String>(value: "")
        let isShowStickerReceived = PublishRelay<Bool>()
        let isPopVC = PublishRelay<Void>()
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    private var memberCache: [String: Member] = [:]
    private var myMissions = [Mission]()
    private var pendingCommits = DisposeBag()

    // MARK: - Init

    init(
        user: User,
        memberCache: [String: Member],
        useCase: MyMissionUseCaseProtocol,
        mapper: MissionMapping,
    ) {
        self.useCase = useCase
        state.user.accept(user)
        self.memberCache = memberCache
        self.mapper = mapper
        bind()
    }

    // MARK: - Bind

    private func bind() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .viewDidLoad:
                    owner.fetchMissions()
                case .selectFilter(let index):
                    owner.state.selectedFilter.accept(index)
                    owner.filterMyMissions(index: index)
                case .didTapStatusButton(let item):
                    let missionID = item.mission!.missionID
                    owner.handleMissionCompleteButtonTapped(missionID: missionID)
                    owner.state.completedMissionTitle.accept(item.mission!.title)
                case .didTapCompleteCancelButton:
                    owner.cancelMissionComplete()
                case .didTapBackButton:
                    owner.state.isPopVC.accept(())
                }
            }
            .disposed(by: disposeBag)
    }

    /// 유저에게 할당된 미션 바인딩
    private func fetchMissions() {
        guard let user = state.user.value else { return }
        useCase.fetchMissions(to: user.userID, ofGroup: user.groupID)
            .do { [weak self] myMissions in
                self?.myMissions = myMissions
                self?.setMissionFilters(missions: myMissions)
            }
            .map { [weak self] in
                guard let self else { return [] }
                return mapper.map(myMissions: $0, member: memberCache)
                    .map { MyMissionItem.mission($0) }
                    .filter {
                        // 미션완료 시 새로 미션을 fetch하기 때문에 필터링 유지
                        let missionFilter = self.state.missionFilters.value
                        let selectedFilter = missionFilter[self.state.selectedFilter.value].status!
                        guard selectedFilter.status != .none else { return true }
                        return $0.mission!.status == selectedFilter.status
                    }
            }
            .bind(to: state.filteredMissions)
            .disposed(by: disposeBag)
    }

    /// 미션 필터 셋팅
    private func setMissionFilters(missions: [Mission]) {
        let statuses: [MissionStatus?] = [.none, .assigned, .completed, .failed]

        let filter = statuses.map { status in
            let count = status == .none ? missions.count : missions.count(where: { $0.status == status })
            return MyMissionItem.status(.init(status: status, count: count))
        }

        state.missionFilters.accept(filter)
        state.selectedFilter.accept(state.selectedFilter.value)
    }

    /// 미션 완료 바인딩
    ///
    /// 전달받은 미션의 ID로 myMissions에서 해당 미션을 찾아 UI를 우선 업데이트,
    /// 4초간 대기 후 캐시 업데이트 및 API 호출
    private func handleMissionCompleteButtonTapped(missionID: String) {
        guard let user = state.user.value else { return }
        updateMissionItem(missionID: missionID)
        state.isShowStickerReceived.accept(true)

        // cancelMissionComplete() 호출 시 dispose되는 Observable
        Observable<Void>.just(())
            .delay(.seconds(3), scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<Mission> in
                guard let self else { return .empty() }
                let missionToUpdate = updateMissionCache(missionID: missionID)
                guard let mission = missionToUpdate else { return .empty() }
                return useCase.updateMissionStatus(for: mission, ofGroup: user.groupID, to: .completed)
            }
            .flatMap { [weak self] mission -> Observable<Void> in
                guard let self else { return .empty() }
                return useCase.createSticker(user: user, mission: mission)
            }
            .subscribe()
            .disposed(by: pendingCommits)
    }

    // MARK: - Methods

    /// UI에서 미션 업데이트
    private func updateMissionItem(missionID: String) {
        let items = state.filteredMissions.value
        let updated = items.map { item in
            let mission = item.mission!
            if mission.missionID == missionID {
                let updated = mission.makeCopyCompleted()
                return MyMissionItem.mission(updated)
            } else {
                return item
            }
        }
        state.filteredMissions.accept(updated)
    }

    /// 도메인 미션 캐시에서 미션 업데이트
    private func updateMissionCache(missionID: String) -> Mission? {
        guard let index = myMissions.firstIndex(where: { $0.missionID == missionID }) else { return nil }
        let missionToUpdate = myMissions[index]
        let updated = missionToUpdate.makeCopyCompleted()
        myMissions[index] = updated
        return updated
    }

    /// 토스트 “취소하기” 버튼 눌렀을 때 호출
    private func cancelMissionComplete() {
        pendingCommits = DisposeBag()
        let cachedMissions = mapper
            .map(myMissions: myMissions, member: memberCache)
            .map { MyMissionItem.mission($0) }
        state.filteredMissions.accept(cachedMissions)
        state.isShowStickerReceived.accept(false)
    }

    private func filterMyMissions(index: Int) {
        let filter = state.missionFilters.value[index]
        let filteredMissions = filter.status!.status == .none
            ? myMissions
            : myMissions.filter { $0.status == filter.status!.status }

        let items = mapper
            .map(myMissions: filteredMissions, member: memberCache)
            .map { MyMissionItem.mission($0) }
        state.filteredMissions.accept(items)
    }
}
