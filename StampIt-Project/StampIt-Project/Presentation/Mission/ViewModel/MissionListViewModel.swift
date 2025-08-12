//
//  MissionListViewModel.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/4/25.
//

import Foundation
import RxSwift
import RxRelay

final class MissionListViewModel: ViewModelProtocol {
    enum Action {
        case onAppear
        case searchTextChanged(String)
        case didSelectTableViewCell(SampleMission)
        case didSelectCollectionViewCell(IndexPath)
        case toggleFavorite(IndexPath)
    }
    
    struct State {
        var missions = BehaviorRelay<[SampleMission]>(value: []) // 뷰에 반영되는 샘플 미션 데이터
        var searchText = BehaviorRelay<String>(value: "")
        var selectedCategory = BehaviorRelay<MissionCategory?>(value: nil)
        var isOnlyFavorite = BehaviorRelay<Bool>(value: false) // 즐겨찾기 등록된 미션만 보여줘야 하는지 true/false
        var recommendedMissions: [SampleMission] = []
    }
    
    var action = PublishRelay<Action>()
    var state = State()
    
    var disposeBag = DisposeBag()
    
    private let missionUseCaseImpl: MissionUseCase
    private var _missions: [SampleMission] = [] // 샘플 미션 원본 데이터
    
    init(missionUseCaseImpl: MissionUseCase) {
        self.missionUseCaseImpl = missionUseCaseImpl
        
        bind()
        
        bindFilterMisson()
    }
    
    private func bind() {
        action
            .subscribe { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .onAppear:
                    let missions = missionUseCaseImpl.fetchSampleMission()
                    let sortedMissions = sort(missions)
                    state.missions.accept(sortedMissions)
                    _missions = sortedMissions
                case .searchTextChanged(let searchText):
                    state.searchText.accept(searchText)
                    print("searchText: \(searchText)")
                case .didSelectTableViewCell(let mission):
                    print("didSelectTableViewCell: \(mission.title)")
                    donate(.tapMission, to: mission)
                case .didSelectCollectionViewCell(let indexPath):
                    if indexPath.item == 0 {
                        state.selectedCategory.accept(nil)
                        state.isOnlyFavorite.accept(false)
                        print("전체보기")
                    } else if indexPath.item == 1 {
                        state.selectedCategory.accept(nil)
                        state.isOnlyFavorite.accept(true)
                        print("즐겨찾기")
                    } else {
                        let category = MissionCategory.allCases[indexPath.item - 2]
                        state.selectedCategory.accept(category)
                        state.isOnlyFavorite.accept(false)
                        print("category: \(category.title)")
                    }
                case .toggleFavorite(let indexPath):
                    let mission = state.missions.value[indexPath.row]
                    guard let missionIndex = _missions.firstIndex(where: { $0.missionId == mission.missionId }) else { return }
                    
                    _missions[missionIndex].isFavorite.toggle()
                    missionUseCaseImpl.updateSampleMission(mission: _missions[missionIndex])
                    
                    state.searchText.accept(state.searchText.value) // 뷰 업데이트 트리거
                }
            }
            .disposed(by: disposeBag)
    }
    
    // 미션 검색 + 카테고리 선택
    private func bindFilterMisson() {
        Observable.combineLatest(state.searchText, state.selectedCategory, state.isOnlyFavorite)
            .map { [weak self] searchText, selectedCategory, isOnlyFavorite -> [SampleMission] in
                guard let self else { return [] }
                
                // 단어 단위로 분할
                let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let keywords = trimmedText
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                
                let filteredMissions = _missions.filter { mission in
                    // 즐겨찾기 필터
                    if isOnlyFavorite, !mission.isFavorite {
                        return false
                    }
                    
                    // 카테고리 필터
                    if let category = selectedCategory, mission.category != category {
                        return false
                    }
                    
                    // 검색어 필터
                    if keywords.isEmpty {
                        return true
                    }
                    
                    // 위에서 분할한 단어들이 미션 제목에 포함되는지 확인
                    let title = mission.title.replacingOccurrences(of: " ", with: "")
                    return keywords.allSatisfy { keyword in
                        title.localizedStandardContains(keyword)
                    }
                }
                
                return sort(filteredMissions)
            }
            .bind(to: state.missions)
            .disposed(by: disposeBag)
    }
    
    // 정렬 우선순위: 1순위 즐겨찾기 여부(true/false) -> 2순위 추천 점수(최대 3개) -> 3순위 미션 타이틀명
    private func sort(_ missions: [SampleMission]) -> [SampleMission] {
        // 우선 전체 데이터를 타이틀명 기준으로 정렬
        let missions = missions.sorted { $0.title < $1.title }
        
        // 전체 데이터를 즐겨찾기 여부에 따라 2개로 분리
        let favoriteMissions = missions.filter {
            $0.isFavorite
        }
        
        let noFavoriteMissions = missions.filter {
            !$0.isFavorite
        }
        
        // 즐겨찾기 false 데이터 중 추천 미션 선정(최대 3개)
        let recommendedMissions = recommend(among: noFavoriteMissions)
        state.recommendedMissions = recommendedMissions
        let ids = recommendedMissions.map { $0.missionId }
        
        // 나머지 데이터
        let remainingMissions = noFavoriteMissions.filter {
            !ids.contains($0.missionId)
        }
        
        return favoriteMissions + recommendedMissions + remainingMissions
    }
    
    // 추천 미션 선정(최대 3개)
    private func recommend(among missions: [SampleMission]) -> [SampleMission] {
        let recommendedMissions = missions
            .filter { $0.score >= 1.0 } // 점수가 1.0 이상인 미션만 추천
            .sorted { $0.score > $1.score } // 점수 순 정렬
            .prefix(3) // 상위 3개만 추출
        return Array(recommendedMissions)
    }
    
    // 미션별 추천 점수 적립
    // 어떤 이벤트가 일어날 때, 해당 미션에 이벤트별 점수를 적립(예: 사용자가 미션 전달하기를 완료하면 해당 미션에 0.4점 부여)
    func donate(_ event: Event, to mission: SampleMission) {
        guard var mission = missionUseCaseImpl.fetchSampleMission(withId: mission.missionId).first else { return }
        
        mission.score += event.relevance // 이벤트별 점수를 적립
        
        missionUseCaseImpl.updateSampleMission(mission: mission)
    }
}
