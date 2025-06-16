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
        var selectedCategory = BehaviorRelay<MissionCategory?>(value: nil)
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
        
        bindFilterMisson()
        
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
                }
            }
            .disposed(by: disposeBag)
    }
    
    // 미션 검색 + 카테고리 선택
    private func bindFilterMisson() {
        Observable.combineLatest(state.searchText, state.selectedCategory)
            .map { [weak self] searchText, selectedCategory -> [SampleMission] in
                guard let self else { return [] }
                
                // 단어 단위로 분할
                let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let keywords = trimmedText
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                
                return _missions.filter { mission in
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
            }
            .bind(to: state.missions)
            .disposed(by: disposeBag)
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
