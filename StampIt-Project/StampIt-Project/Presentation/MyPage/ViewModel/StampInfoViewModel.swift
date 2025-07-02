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
            .subscribe(with: self) { owned, action in
                switch action {
                case .load(let missionId):
                    owned.fetchMission(missionId: missionId)
                case .closeButtonTapped:
                    owned.state.isDismissed.accept(true)
                }
            }.disposed(by: disposeBag)
    }
    
    private func fetchMission(missionId: String) {
        missionUseCase.fetchMission(with: missionId)
            .flatMap { [weak self] mission -> Observable<(MissionUI, User?)> in
                guard let self, let mission else { return .empty() }
                let userId = mission.assignedBy
                return myPageUseCase.fetchUserOnce(userId: userId)
                    .map { user in (mission, user) }
            }
            .subscribe(with: self) { owned, result in
                var (mission, user) = result
                
                if let user {
                    mission.assignedBy = user.nickname
                } else {
                    mission.assignedBy = "탈퇴한 유저"
                }
                
                owned.state.mission.accept(mission)
            }.disposed(by: disposeBag)
    }
}
