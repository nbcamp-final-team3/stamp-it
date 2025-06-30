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

    private let missionUseCase: MemberMissionUseCaseProtocol
    private let memberMapper: MemberMapping
    private let missionMapper: MissionMapping

    // MARK: - Action & State

    enum Action {
        case viewDidLoad
        case didTapBackButton
        case selectFilter(Int)
        case didTapSendMission
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let members = BehaviorRelay<[MemberMissionItem]>(value: [])
        let missions = BehaviorRelay<[MemberMissionItem]>(value: [])
        let selectedMember = BehaviorRelay<Int>(value: 0)
        let isPopVC = PublishRelay<Void>()
        let isMoveToMissionTap = PublishRelay<Void>()
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    private var memberCache: [String: Member] = [:]
    private var missionCache: [Mission] = []

    // MARK: - Init

    init(
        user: User,
        memberCache: [String: Member],
        useCase: MemberMissionUseCaseProtocol,
        memberMapper: MemberMapper,
        missionMapper: MissionMapping,
    ) {
        self.missionUseCase = useCase
        state.user.accept(user)
        self.memberCache = memberCache
        self.memberMapper = memberMapper
        self.missionMapper = missionMapper
        bind()
    }

    // MARK: - Bind

    private func bind() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .viewDidLoad:
                    owner.setMembers()
                    owner.fetchMissions()
                case .didTapSendMission:
                    owner.state.isMoveToMissionTap.accept(())
                case .selectFilter(let index):
                    owner.filterMissions(index: index)
                    owner.state.selectedMember.accept(index)
                case .didTapBackButton:
                    owner.state.isPopVC.accept(())
                }
            }
            .disposed(by: disposeBag)
    }

    /// 소속 그룹의 멤버 불러오기
    private func setMembers() {
        guard let user = state.user.value else { return }
        let allMembersItem = MemberMissionItem.allMember(image: .mascotGroup, title: "전체")
        let members = Array(memberCache.values.filter { $0.userID != user.userID })
        let memberItems = memberMapper
            .map(members: members, userID: user.userID)
            .map { MemberMissionItem.member($0) }

        state.members.accept([allMembersItem] + memberItems)
    }

    /// 유저가 그룹 구성원에게 할당한 미션 바인딩
    private func fetchMissions() {
        guard let user = state.user.value else { return }
        missionUseCase.fetchMissions(by: user.userID, ofGroup: user.groupID)
            .map { [weak self] missions in
                guard let self else { return [] }
                missionCache = missions
                return missionMapper
                    .map(memberMission: missions, member: memberCache)
                    .map { MemberMissionItem.mission($0) }
            }
            .bind(to: state.missions)
            .disposed(by: disposeBag)
    }

    private func filterMissions(index: Int) {
        let filter = state.members.value[index]

        var filteredMissions: [Mission] = []
        switch filter {
        case .allMember(_, _):
            filteredMissions = missionCache
        case .member(let member):
            filteredMissions = missionCache.filter { $0.assignedTo == member.memberID }
        default: break
        }

        let items = missionMapper
            .map(memberMission: filteredMissions, member: memberCache)
            .map { MemberMissionItem.mission($0) }
        state.missions.accept(items)
    }
}
