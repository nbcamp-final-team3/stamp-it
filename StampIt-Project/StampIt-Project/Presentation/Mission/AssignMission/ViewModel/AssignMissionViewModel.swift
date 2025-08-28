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
        case didFillOutTitle(String)
        case didSelectMember(Member)
        case didSelectDueDate(Date)
        case didTapAssignButton
    }
    
    struct State {
        var mission = BehaviorRelay<SampleMission?>(value: nil)
        var members = BehaviorRelay<[Member]>(value: [])
        var selectedMember = BehaviorRelay<Member?>(value: nil)
        var dueDate = BehaviorRelay<Date>(value: Date())
        var canSubmit = BehaviorRelay<Bool>(value: false)
        var customMissionTitle = BehaviorRelay<String?>(value: nil)
    }
    
    var action = PublishRelay<Action>()
    var state = State()
    
    var disposeBag = DisposeBag()
    
    var onSuccess: (() -> Void)? // 새로운 미션이 생성되어 파이어베이스까지 저장 완료되었을 때 호출
    
    private let missionUseCaseImpl: MissionUseCase
    private var user: User?
    
    private var canSubmit: Bool {
        // 멤버 선택이 안되어 있으면 false
        if state.selectedMember.value == nil { return false }
        
        // 만약 커스텀 미션이 아니라면(샘플 미션이라면) 멤버 선택은 이미 되어 있으므로 true
        if let mission = state.mission.value, !mission.title.isEmpty { return true }
        
        // 만약 커스텀 미션이고, 미션 제목을 입력했다면 true
        if let title = state.customMissionTitle.value, !title.isEmpty { return true }
        
        return false
    }
    
    init(
        mission: SampleMission? = nil,
        selectedMember: Member? = nil,
        missionUseCaseImpl: MissionUseCase
    ) {
        if let mission {
            state.mission.accept(mission)
        } else {
            let mission = SampleMission(missionId: "", title: "", description: nil, category: .custom)
            state.mission.accept(mission)
        }
        
        // 홈 화면에서 특정 멤버가 선택된 상태에서 미션 화면으로 진입할 때 사용
        if let selectedMember {
            var members: [Member] = []
            members.append(selectedMember)
            state.members.accept(members)
        }
        
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
                    loadMembers()
                    print("mission: \(String(describing: state.mission.value?.title)), members count: \(state.members.value.count)")
                case .didFillOutTitle(let title):
                    state.customMissionTitle.accept(title)
                    state.canSubmit.accept(canSubmit)
                case .didSelectMember(let member):
                    state.selectedMember.accept(member)
                    state.canSubmit.accept(canSubmit)
                    print("selected member: \(member)")
                case .didSelectDueDate(let date):
                    state.dueDate.accept(date)
                    print("due date: \(date)")
                case .didTapAssignButton:
                    print("did tap assign button")
                    createMission()
                        .subscribe { [weak self] in
                            print("mission created.")
                            self?.onSuccess?()
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
                
                // 유저 정보를 받으면 멤버 정보 요청
                // 홈 화면에서 특정 멤버가 선택된 상태에서 미션 화면으로 진입할 때는 멤버 정보 패치 불필요
                if state.members.value.isEmpty {
                    fetchMembers()
                }
                
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
                let filteredMembers = members.filter { $0.userID != user.userID }
                self?.state.members.accept(filteredMembers)
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    // 미션 정보 저장
    private func createMission() -> Observable<Void> {
        let member = state.selectedMember.value
        let dueDate = state.dueDate.value
        guard let member, let user else {
            return Observable.error(NSError(domain: "user data is nil.", code: 0, userInfo: nil))
        }
        
        let title = state.customMissionTitle.value ?? state.mission.value!.title
        let createDate = Date()
        let category = state.mission.value!.category
        
        let mission = Mission(
            missionID: UUID().uuidString,
            title: title,
            assignedTo: member.userID,
            assignedBy: user.userID,
            createDate: createDate,
            dueDate: dueDate,
            status: MissionStatus.assigned,
            imageURL: "",
            category: category)
        
        // 전달한 미션 정보를 코어데이터에 저장
        missionUseCaseImpl.saveMissionData(title: title, assigneeId: member.userID, assigneeNickname: member.nickname, createDate: createDate, dueDate: dueDate, category: category)
        
        return missionUseCaseImpl.createMission(groupId: user.groupID, mission: mission)
    }
}
