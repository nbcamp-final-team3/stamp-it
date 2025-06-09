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
    
    init(mission: SampleMission) {
        self.mission = mission
        
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
                    output.members.accept(loadMembers())
                    print("mission: \(String(describing: output.mission.value?.title)), members: \(output.members.value.count)")
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
    
    private func loadMembers() -> [Member] {
        let dummyMembers: [Member] = [
            Member(userID: "12345", nickname: "유진", joinedAt: Date(), isLeader: true),
            Member(userID: "67890", nickname: "엄마", joinedAt: Date(), isLeader: false),
            Member(userID: "112233", nickname: "파덜", joinedAt: Date(), isLeader: false),
        ]
        
        return dummyMembers
    }
}
