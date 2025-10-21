//
//  AssignMissionViewModel.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/8/25.
//

import Foundation
import RxSwift
import RxRelay
import FoundationModels

final class AssignMissionViewModel: ViewModelProtocol {
    enum Action {
        case onAppear
        case titleDidChange(String)
        case didSelectMember(Member)
        case didSelectDueDate(Date)
        case didTapAssignButton
        case toggleFavorite
        case textFieldIsEditing(Bool)
    }
    
    struct State {
        var mission = BehaviorRelay<SampleMission?>(value: nil)
        var members = BehaviorRelay<[Member]>(value: [])
        var selectedMember = BehaviorRelay<Member?>(value: nil)
        var dueDate = BehaviorRelay<Date>(value: Date())
        var canSubmit = BehaviorRelay<Bool>(value: false)
        var textFieldIsEditing = BehaviorRelay<Bool>(value: false)
        var suggestions = BehaviorRelay<[Suggestion]>(value: [])
    }
    
    var action = PublishRelay<Action>()
    var state = State()
    
    var disposeBag = DisposeBag()
    
    var onSuccess: (() -> Void)? // 새로운 미션이 생성되어 파이어베이스까지 저장 완료되었을 때 호출
    
    private let missionUseCaseImpl: MissionUseCase
    private var user: User?
    private var userData: [MissionData] = [] // 과거 데이터(사용자가 다른 멤버에게 전달했던 미션)
    private var aiSuggestions: [String] = []
    
    private var canSubmit: Bool {
        // 멤버 선택이 안되어 있으면 false
        if state.selectedMember.value == nil { return false }
        
        // 만약 커스텀 미션이 아니라면(샘플 미션이라면) 멤버 선택은 이미 되어 있으므로 true
        if let mission = state.mission.value, !mission.title.isEmpty { return true }
        
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
                    
                    userData = missionUseCaseImpl.fetchMissionData()
                    
                    // AI 추천 데이터 미리 생성(generating 하는데 시간이 걸리므로 미리 만들어 놓음)
                    if #available(iOS 26.0, *) {
                        let generator = MissionGenerator(userData: userData)
                        generator.prewarm() // 현재 로직에서는 불필요하나, MissionGenerator 인스턴스 생성 시점과 suggestMisson 메서드 호출 시점이 (현저하게) 다르면 필요할 수 있어 남겨 놓음.
                        Task {
                            await generator.suggestMission(missionCount: 3)
                            self.aiSuggestions = generator.suggestions
                        }
                    }
                    
                case .titleDidChange(let title):
                    guard let mission = state.mission.value else { return }
                    let newMission = SampleMission(missionId: mission.missionId, title: title, description: mission.description, category: mission.category)
                    state.mission.accept(newMission)
                    
                    state.canSubmit.accept(canSubmit)
                    
                    let suggestions = generateSuggestion() + aiGenerateSuggestion()
                    state.suggestions.accept(suggestions)
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
                case .toggleFavorite:
                    guard var mission = state.mission.value else { return }
                    mission.isFavorite.toggle()
                    
                    state.mission.accept(mission)
                    missionUseCaseImpl.updateSampleMission(mission: mission)
                case .textFieldIsEditing(let isEditing):
                    state.textFieldIsEditing.accept(isEditing)
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
        
        let title = state.mission.value?.title ?? ""
        let createDate = Date()
        let category = state.mission.value?.category ?? MissionCategory.custom
        
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
    
    private func generateSuggestion() -> [Suggestion] {
        guard !userData.isEmpty else { return [] }
        let inputText = state.mission.value?.title
        var suggestions: [Suggestion] = []
        
        // 1. 과거 데이터 기반 추천데이터 생성
        if let inputText, !inputText.isEmpty {
            // 단어 단위로 분할
            let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            let keywords = trimmedText
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            userData
                .filter { mission in
                    // 위에서 분할한 단어들이 미션 제목에 포함되는지 확인
                    let title = mission.title.replacingOccurrences(of: " ", with: "")
                    return keywords.allSatisfy { keyword in
                        title.localizedStandardContains(keyword)
                    }
                }
                .forEach { mission in
                    if !suggestions.contains(where: { $0.title == mission.title }) {
                        let suggestion = Suggestion(title: mission.title, source: .history)
                        suggestions.append(suggestion)
                    }
                }
        }
        
        return suggestions
    }
    
    private func aiGenerateSuggestion() -> [Suggestion] {
        if !aiSuggestions.isEmpty {
            var suggestions: [Suggestion] = []
            aiSuggestions.forEach {
                let suggestion = Suggestion(title: $0, source: .AI)
                suggestions.append(suggestion)
            }
            return suggestions
        }
        return []
    }
}
