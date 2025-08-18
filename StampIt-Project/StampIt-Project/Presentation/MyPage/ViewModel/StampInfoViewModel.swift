//
//  StampInfoViewModel.swift
//  StampIt-Project
//
//  Created by kingj on 7/1/25.
//

import RxSwift
import RxRelay

final class StampInfoViewModel: ViewModelProtocol {
    
    // MARK: - Dependency
    
    private let missionUseCase: MissionUseCase
    private let myPageUseCase: MyPageUseCaseProtocol
    
    // MARK: - Action & State
    
    enum Action {
        case load(missionId: String)
        case closeButtonTapped
    }
    
    struct State {
        let mission = BehaviorRelay<MissionUI?>(value: nil)
        let isDismissed = BehaviorRelay<Bool>(value: false)
    }
    
    // MARK: - Properties
    
    var disposeBag = DisposeBag()
    var action = PublishRelay<Action>()
    var state = State()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(
        missionUseCase: MissionUseCase,
        myPageUseCase: MyPageUseCaseProtocol
    ) {
        self.missionUseCase = missionUseCase
        self.myPageUseCase = myPageUseCase
        bindAction()
    }
    
    // MARK: - Bind
    
    private func bindAction() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .load(let missionId):
                    owner.fetchMission(missionId: missionId)
                case .closeButtonTapped:
                    owner.state.isDismissed.accept(true)
                }
            }.disposed(by: disposeBag)
    }
    
    private func fetchMission(missionId: String) {
        missionUseCase.fetchMission(with: missionId)
            .flatMap { [weak self] mission -> Observable<(MissionUI, User?)> in
                guard let self, let mission else { return .empty() }
                let userId = mission.nickname
                return myPageUseCase.fetchUserOnce(userId: userId)
                    .map { user in (mission, user) }
            }
            .subscribe(with: self) { owner, result in
                var (mission, user) = result
                
                if let user {
                    mission.nickname = user.nickname
                } else {
                    mission.nickname = "탈퇴한 유저"
                }
                
                owner.state.mission.accept(mission)
            }.disposed(by: disposeBag)
    }
}
