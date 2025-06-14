//
//  MissionListViewModel.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/4/25.
//

import UIKit
import RxSwift
import RxRelay

final class MissionListViewModel: MissionViewModelProtocol {
    enum Input {
        case onAppear
        case searchTextChanged(String)
        case didSelectTableViewCell(SampleMission)
        case didSelectCollectionViewCell(IndexPath)
    }
    
    struct Output {
        var missions = BehaviorRelay<[SampleMission]>(value: []) // 뷰에 반영되는 샘플 미션 데이터
        var searchText = BehaviorRelay<String>(value: "")
        var snapshot = BehaviorRelay<NSDiffableDataSourceSnapshot<Section, Item>?>(value: nil)
    }
    
    var input = PublishRelay<Input>()
    var output = Output()
    
    var disposeBag = DisposeBag()
    
    private let missionUseCaseImpl: MissionUseCase
    private var _missions: [SampleMission] = [] // 샘플 미션 JSON 원본 데이터
    
    init(missionUseCaseImpl: MissionUseCase = MissionUseCaseImpl()) {
        self.missionUseCaseImpl = missionUseCaseImpl
        
        bind()
        
        updateSnapshot()
    }
    
    private func bind() {
        input
            .subscribe { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .onAppear:
                    missionUseCaseImpl.loadSampleMission()
                        .subscribe { [weak self] missions in
                            guard let self else { return }
                            
                            output.missions.accept(missions)
                            _missions = missions
                        } onFailure: { error in
                            print(error)
                        }
                        .disposed(by: disposeBag)
                case .searchTextChanged(let searchText):
                    output.searchText.accept(searchText)
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
        guard !output.searchText.value.isEmpty else {
            output.missions.accept(_missions)
            return
        }
        
        let filteredMissions = _missions
            .filter { $0.title.localizedStandardContains(output.searchText.value.trimmingCharacters(in: .whitespaces)) } // 검색어 맨앞 공백 무시
        output.missions.accept(filteredMissions)
    }
    
    private func filterMission(indexPath: IndexPath) {
        switch indexPath.item {
        case 0:
            output.missions.accept(_missions)
            print("전체보기")
        case let x where x > 0:
            let category = MissionCategory.allCases[x - 1]
            let filteredMissions = _missions
                .filter { $0.category == category }
            output.missions.accept(filteredMissions)
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
        
        output.snapshot.accept(snapshot)
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
