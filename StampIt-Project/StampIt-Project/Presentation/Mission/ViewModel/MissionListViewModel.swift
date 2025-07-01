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
    }
    
    var action = PublishRelay<Action>()
    var state = State()
    
    var disposeBag = DisposeBag()
    
    private let missionUseCaseImpl: MissionUseCase
    private var _missions: [SampleMission] = [] // 샘플 미션 JSON 원본 데이터
    
    init(missionUseCaseImpl: MissionUseCase) {
        self.missionUseCaseImpl = missionUseCaseImpl
        
        bind()
        
        bindFilterMisson()
        
        loadFavorites()
    }
    
    private func bind() {
        action
            .subscribe { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .onAppear:
                    missionUseCaseImpl.loadSampleMission()
                        .subscribe { [weak self] missions in
                            guard let self else { return }
                            
                            let sortedMissions = sort(missions)
                            state.missions.accept(sortedMissions)
                            _missions = sortedMissions
                        } onFailure: { error in
                            print(error)
                        }
                        .disposed(by: disposeBag)
                case .searchTextChanged(let searchText):
                    state.searchText.accept(searchText)
                    print("searchText: \(searchText)")
                case .didSelectTableViewCell(let mission):
                    print("didSelectTableViewCell: \(mission.title)")
                case .didSelectCollectionViewCell(let indexPath):
                    if indexPath.item == 0 {
                        state.selectedCategory.accept(nil)
                        print("전체보기")
                    } else {
                        let category = MissionCategory.allCases[indexPath.item - 1]
                        state.selectedCategory.accept(category)
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
                    UserDefaults.standard.set(Array(favorites), forKey: "favorites")
                }
            }
            .disposed(by: disposeBag)
    }
    
    // 미션 검색 + 카테고리 선택
    private func bindFilterMisson() {
        Observable.combineLatest(state.searchText, state.selectedCategory, state.favorites)
            .map { [weak self] searchText, selectedCategory, _ -> [SampleMission] in
                guard let self else { return [] }
                
                // 단어 단위로 분할
                let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let keywords = trimmedText
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                
                let filteredMissions = _missions.filter { mission in
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
    
    // 정렬 우선순위: 1순위 즐겨찾기 여부 -> 2순위 미션 타이틀명
    private func sort(_ missions: [SampleMission]) -> [SampleMission] {
        // 우선 전체 데이터를 타이틀명 기준으로 정렬
        let missions = missions.sorted { $0.title < $1.title }
        
        let favorites = state.favorites.value
        
        let favoriteMissions = missions.filter {
            favorites.contains($0.missionId)
        }
        
        let noFavoriteMissions = missions.filter {
            !favorites.contains($0.missionId)
        }
        
        // 즐겨찾기 등록된 미션을 앞으로, 나머지는 뒤로
        return favoriteMissions + noFavoriteMissions
    }
    
    // 즐겨찾기 샘플미션 로드
    private func loadFavorites() {
        let favorites = UserDefaults.standard.stringArray(forKey: "favorites") ?? []
        state.favorites.accept(Set(favorites))
    }
}
