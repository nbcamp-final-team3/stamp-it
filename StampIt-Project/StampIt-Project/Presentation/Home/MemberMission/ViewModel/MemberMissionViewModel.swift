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
    private let mapper: MissionMapping

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

    init(
        user: User,
        memberCache: [String: Member],
        useCase: MemberMissionUseCaseProtocol,
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
                return mapper.map(memberMission: $0, member: memberCache)
                    .map { MemberMissionItem.mission($0) }
            }
            .bind(to: state.missions)
            .disposed(by: disposeBag)
    }
}
