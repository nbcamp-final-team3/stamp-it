//
//  MissionListViewModel.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/4/25.
//

import UIKit
import RxSwift
import RxRelay

final class MissionListViewModel: ViewModelProtocol {
    enum Action {
        case onAppear
        case searchTextChanged(String)
        case didSelectTableViewCell(SampleMission)
        case didSelectCollectionViewCell(IndexPath)
    }
    
    struct State {
        var missions = BehaviorRelay<[SampleMission]>(value: []) // 뷰에 반영되는 샘플 미션 데이터
        var searchText = BehaviorRelay<String>(value: "")
        var snapshot = BehaviorRelay<NSDiffableDataSourceSnapshot<Section, Item>?>(value: nil)
    }
    
    var action = PublishRelay<Action>()
    var state = State()
    
    var disposeBag = DisposeBag()
    
    private let missionUseCaseImpl: MissionUseCase
    private var _missions: [SampleMission] = [] // 샘플 미션 JSON 원본 데이터
    
    init(missionUseCaseImpl: MissionUseCase = MissionUseCaseImpl()) {
        self.missionUseCaseImpl = missionUseCaseImpl
        
        bind()
        
        updateSnapshot()
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
                            
                            let sortedMissions = missions.sorted { $0.title < $1.title }
                            state.missions.accept(sortedMissions)
                            _missions = sortedMissions
                        } onFailure: { error in
                            print(error)
                        }
                        .disposed(by: disposeBag)
                case .searchTextChanged(let searchText):
                    state.searchText.accept(searchText)
                    print("searchText: \(searchText)")
                    searchMission()
                case .didSelectTableViewCell(let mission):
                    print("didSelectTableViewCell: \(mission.title)")
                case .didSelectCollectionViewCell(let indexPath):
                    filterMission(indexPath: indexPath)
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func searchMission() {
        // 검색어가 없으면 원본 데이터를 뷰에 반영하고 리턴
        guard !state.searchText.value.isEmpty else {
            state.missions.accept(_missions)
            return
        }
        
        let searchText = state.searchText.value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 단어 단위로 쪼갠 후, 각 단어가 미션 제목에 포함되는지 확인
        let filteredMissions = _missions.filter { mission in
            let title = mission.title.replacingOccurrences(of: " ", with: "")
            let keywords = searchText
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            
            return keywords.allSatisfy { keyword in
                title.localizedStandardContains(keyword)
            }
        }
        
        state.missions.accept(filteredMissions)
    }
    
    private func filterMission(indexPath: IndexPath) {
        switch indexPath.item {
        case 0:
            state.missions.accept(_missions)
            print("전체보기")
        case let x where x > 0:
            let category = MissionCategory.allCases[x - 1]
            let filteredMissions = _missions
                .filter { $0.category == category }
            state.missions.accept(filteredMissions)
            print("category: \(category.title)")
        default:
            break
        }
    }
    
    // 컬렉션 뷰 스냅샷 업데이트
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.category])
        
        var items: [Item] = []
        items.append(.all)
        MissionCategory.allCases.forEach {
            items.append(.category($0))
        }
        snapshot.appendItems(items)
        
        state.snapshot.accept(snapshot)
    }
}

// 컬렉션 뷰 섹션/아이템 정의
extension MissionListViewModel {
    enum Section: Hashable {
        case category
    }
    
    enum Item: Hashable {
        case all
        case category(MissionCategory)
    }
}
