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
        case didTapStatusButton(MyMissionItem)
        case didTapCompleteCancelButton
        case didTapBackButton
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let missions = BehaviorRelay<[MyMissionItem]>(value: [])
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
            .do(onNext: { myMissions in
                self.myMissions = myMissions
            })
            .map { [weak self] in
                guard let self else { return [] }
                return mapper.map(myMissions: $0, member: memberCache)
                    .map { MyMissionItem.mission($0) }
            }
            .bind(to: state.missions)
            .disposed(by: disposeBag)
    }

    /// 미션 완료 바인딩
    ///
    /// 전달받은 미션의 ID로 myMissions에서 해당 미션을 찾아 UI를 우선 업데이트,
    /// 4초간 대기 후 캐시 업데이트 및 API 호출
    func handleMissionCompleteButtonTapped(missionID: String) {
        updateMissionItem(missionID: missionID)
        state.isShowStickerReceived.accept(true)

        // cancelMissionComplete() 호출 시 dispose되는 Observable
        Observable<Void>.just(())
            .delay(.seconds(3), scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<Mission> in
                guard let self else { return .empty() }
                let missionToUpdate = updateMissionCache(missionID: missionID)
                guard let mission = missionToUpdate,
                      let user = state.user.value else { return .empty() }
                return useCase.updateMissionStatus(for: mission, ofGroup: user.groupID, to: .completed)
            }
            .flatMap { [weak self] mission -> Observable<Void> in
                guard let self, let user = state.user.value else { return .empty() }

                return useCase.createSticker(
                    userId: user.userID,
                    groupId: user.groupID,
                    missionTitle: mission.title,
                    maxSticker: 30, // TODO: pin 번호 계산용
                    stickerType: StickerType.stampRed.rawValue, // TODO: 스티커 타입 결정 로직 추가
                    assignedBy: mission.assignedBy,
                )
            }
            .subscribe()
            .disposed(by: pendingCommits)
    }

    // MARK: - Methods

    /// UI에서 미션 업데이트
    private func updateMissionItem(missionID: String) {
        let items = state.missions.value
        let updated = items.map { item in
            let mission = item.mission!
            if mission.missionID == missionID {
                let updated = HomeMyMission(
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
        guard let index = myMissions.firstIndex(where: { $0.missionID == missionID }) else { return nil }
        let missionToUpdate = myMissions[index]
        let updated = Mission(
            missionID: missionToUpdate.missionID,
            title: missionToUpdate.title,
            assignedTo: missionToUpdate.assignedTo,
            assignedBy: missionToUpdate.assignedBy,
            createDate: missionToUpdate.createDate,
            dueDate: missionToUpdate.dueDate,
            status: .completed,
            imageURL: missionToUpdate.imageURL,
            category: missionToUpdate.category
        )
        myMissions[index] = updated
        return updated
    }

    /// 토스트 “취소하기” 버튼 눌렀을 때 호출
    func cancelMissionComplete() {
        pendingCommits = DisposeBag()
        let cachedMissions = mapper
            .map(myMissions: myMissions, member: memberCache)
            .map { MyMissionItem.mission($0) }
        state.missions.accept(cachedMissions)
        state.isShowStickerReceived.accept(false)
    }
}
