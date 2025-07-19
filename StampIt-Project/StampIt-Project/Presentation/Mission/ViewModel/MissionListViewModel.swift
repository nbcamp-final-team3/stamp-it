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
        var favorites = BehaviorRelay<Set<String>>(value: [])
        var isOnlyFavorite = BehaviorRelay<Bool>(value: false) // 즐겨찾기 등록된 미션만 보여줘야 하는지 true/false
        var recommendedMissions: [SampleMission] = []
    }
    
    var action = PublishRelay<Action>()
    var state = State()
    
    var disposeBag = DisposeBag()
    
    private let missionUseCaseImpl: MissionUseCase
    private var _missions: [SampleMission] = [] // 샘플 미션 JSON 원본 데이터
    private var missionScores: [String: Double] = [:] // 미션별 추천 점수
    
    init(missionUseCaseImpl: MissionUseCase) {
        self.missionUseCaseImpl = missionUseCaseImpl
        
        bind()
        
        bindFilterMisson()
        
        loadFavorites()
        loadMissionScores()
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
                    var favorites = state.favorites.value
                    
                    // 토글 형식이므로, 현재 즐겨찾기인 미션을 탭하면 즐겨찾기 해제, 현재 즐겨찾기가 아닌 미션을 탭하면 즐겨찾기 등록
                    if favorites.contains(mission.missionId) {
                        favorites.remove(mission.missionId)
                    } else {
                        favorites.insert(mission.missionId)
                    }
                    state.favorites.accept(favorites)
                    UserDefaults.standard.set(Array(favorites), forKey: UserDefaultsKey.favorites)
                }
            }
            .disposed(by: disposeBag)
    }
    
    // 미션 검색 + 카테고리 선택
    private func bindFilterMisson() {
        Observable.combineLatest(state.searchText, state.selectedCategory, state.isOnlyFavorite, state.favorites)
            .map { [weak self] searchText, selectedCategory, isOnlyFavorite, favorites -> [SampleMission] in
                guard let self else { return [] }
                
                // 단어 단위로 분할
                let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let keywords = trimmedText
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                
                let filteredMissions = _missions.filter { mission in
                    // 즐겨찾기 필터
                    if isOnlyFavorite, !favorites.contains(mission.missionId) {
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
        
        let favorites = state.favorites.value
        
        // 전체 데이터를 즐겨찾기 여부에 따라 2개로 분리
        let favoriteMissions = missions.filter {
            favorites.contains($0.missionId)
        }
        
        let noFavoriteMissions = missions.filter {
            !favorites.contains($0.missionId)
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
    
    // 즐겨찾기 샘플미션 로드
    private func loadFavorites() {
        let favorites = UserDefaults.standard.stringArray(forKey: UserDefaultsKey.favorites) ?? []
        state.favorites.accept(Set(favorites))
    }
    
    // 미션별 추천 점수 로드
    private func loadMissionScores() {
        missionScores = UserDefaults.standard.dictionary(forKey: UserDefaultsKey.missionScores) as? [String: Double] ?? [:]
    }
    
    // 추천 미션 선정(최대 3개)
    private func recommend(among missions: [SampleMission]) -> [SampleMission] {
        let recommendedMissions = missions
            .filter { (missionScores[$0.missionId] ?? 0) >= 1.0 } // 점수가 1.0 이상인 미션만 추천
            .sorted { (missionScores[$0.missionId] ?? 0) > (missionScores[$1.missionId] ?? 0) } // 점수 순 정렬
            .prefix(3) // 상위 3개만 추출
        return Array(recommendedMissions)
    }
    
    // 미션별 추천 점수 적립
    // 어떤 이벤트가 일어날 때, 해당 미션에 이벤트별 점수를 적립(예: 사용자가 미션 전달하기를 완료하면 해당 미션에 0.4점 부여)
    func donate(_ event: Event, to mission: SampleMission) {
        var scores = missionScores
        var score = scores[mission.missionId] ?? 0
        
        score += event.relevance // 이벤트별 점수를 적립
        scores[mission.missionId] = score
        
        missionScores = scores
        UserDefaults.standard.set(scores, forKey: UserDefaultsKey.missionScores)
    }
}

extension MissionListViewModel {
    struct UserDefaultsKey {
        static let favorites = "favorites"
        static let missionScores = "missionScores"
    }
}
