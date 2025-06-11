//
//  AssignMissionViewModel.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/8/25.
//

import Foundation
import RxSwift
import RxRelay

final class AssignMissionViewModel: MissionViewModelProtocol {
    enum Input {
        case onAppear
        case didSelectMember(Member)
        case didSelectDueDate(Date)
        case didTapAssignButton
    }
    
    struct Output {
        var mission = BehaviorRelay<SampleMission?>(value: nil)
        var members = BehaviorRelay<[Member]>(value: [])
        var selectedMember = BehaviorRelay<Member?>(value: nil)
        var dueDate = BehaviorRelay<Date>(value: Date())
    }
    
    var input = PublishRelay<Input>()
    var output = Output()
    
    var disposeBag = DisposeBag()
    
    private let mission: SampleMission
    private let missionUseCaseImpl: MissionUseCase
    
    init(mission: SampleMission, missionUseCaseImpl: MissionUseCase = MissionUseCaseImpl()) {
        self.mission = mission
        self.missionUseCaseImpl = missionUseCaseImpl
        
        bind()
    }
    
    deinit {
        print("deinit AssignMissionViewModel")
    }
    
    private func bind() {
        input
            .subscribe { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .onAppear:
                    output.mission.accept(mission)
                    loadMembers()
                    print("mission: \(String(describing: output.mission.value?.title)), members count: \(output.members.value.count)")
                case .didSelectMember(let member):
                    output.selectedMember.accept(member)
                    print("selected member: \(member)")
                case .didSelectDueDate(let date):
                    output.dueDate.accept(date)
                    print("due date: \(date)")
                case .didTapAssignButton:
                    print("did tap assign button")
                }
            }
            .disposed(by: disposeBag)
    }
    
    // 우선 group ID를 확인 -> group ID를 parameter로 해서 멤버 데이터 조회 -> 받아온 멤버 데이터를 output.members에 반영
    private func loadMembers() {
        missionUseCaseImpl.getCurrentGroupID()
            .flatMap { [weak self] groupID -> Observable<[Member]> in
                guard let self else {
                    return Observable.just([])
                }
                return missionUseCaseImpl.fetchMembers(ofGroup: groupID)
            }
            .subscribe { [weak self] members in
                self?.output.members.accept(members)
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
}
