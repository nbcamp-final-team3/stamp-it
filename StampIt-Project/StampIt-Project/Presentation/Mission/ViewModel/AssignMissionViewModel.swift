//
//  AssignMissionViewModel.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/8/25.
//

import Foundation
import RxSwift
import RxRelay

final class AssignMissionViewModel: ViewModelProtocol {
    enum Action {
        case onAppear
        case didSelectMember(Member)
        case didSelectDueDate(Date)
        case didTapAssignButton
    }
    
    struct State {
        var mission = BehaviorRelay<SampleMission?>(value: nil)
        var members = BehaviorRelay<[Member]>(value: [])
        var selectedMember = BehaviorRelay<Member?>(value: nil)
        var dueDate = BehaviorRelay<Date>(value: Date())
    }
    
    var action = PublishRelay<Action>()
    var state = State()
    
    var disposeBag = DisposeBag()
    
    private let mission: SampleMission
    private let missionUseCaseImpl: MissionUseCase
    private var user: User?
    
    init(mission: SampleMission, missionUseCaseImpl: MissionUseCase = MissionUseCaseImpl()) {
        self.mission = mission
        self.missionUseCaseImpl = missionUseCaseImpl
        
        bind()
    }
    
    deinit {
        print("deinit AssignMissionViewModel")
    }
    
    private func bind() {
        action
            .subscribe { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .onAppear:
                    state.mission.accept(mission)
                    loadMembers()
                    print("mission: \(String(describing: state.mission.value?.title)), members count: \(state.members.value.count)")
                case .didSelectMember(let member):
                    state.selectedMember.accept(member)
                    print("selected member: \(member)")
                case .didSelectDueDate(let date):
                    state.dueDate.accept(date)
                    print("due date: \(date)")
                case .didTapAssignButton:
                    print("did tap assign button")
                    createMission()
                        .subscribe {
                            print("mission created.")
                        } onError: { error in
                            print(error)
                        }
                        .disposed(by: disposeBag)
                }
            }
            .disposed(by: disposeBag)
    }
    
    // 우선 유저 정보를 요청하여 받고 -> 받은 유저 정보을 이용해서 멤버 정보를 받음
    private func loadMembers() {
        missionUseCaseImpl.getCurrentUser()
            .subscribe { [weak self] user in
                guard let self else { return }
                
                self.user = user
                fetchMembers() // 유저 정보를 받으면 멤버 정보 요청
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    // 멤버 정보 패치
    private func fetchMembers() {
        guard let user else { return }
        
        missionUseCaseImpl.fetchMembers(ofGroup: user.groupID)
            .subscribe { [weak self] members in
                self?.state.members.accept(members)
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    // 미션 정보 저장
    private func createMission() -> Observable<Void> {
        let nickname = state.selectedMember.value.map { $0.nickname }
        let dueDate = state.dueDate.value
        guard let nickname, let user else {
            return Observable.error(NSError(domain: "user data or member data is nil.", code: 0, userInfo: nil))
        }
        
        let mission = Mission(
            missionID: mission.missionId,
            title: mission.title,
            assignedTo: nickname,
            assignedBy: user.nickname,
            createDate: Date(),
            dueDate: dueDate,
            status: MissionStatus.assigned,
            imageURL: "",
            category: mission.category)
        
        return missionUseCaseImpl.createMission(groupId: user.groupID, mission: mission)
    }
}
