//
//  MissionListViewModel.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/4/25.
//

import Foundation
import RxSwift
import RxRelay

final class MissionListViewModel: MissionViewModelProtocol {
    enum Input {
        case onAppear
        case searchTextChanged(String)
        case didSelectTableViewCell(SampleMission)
    }
    
    struct Output {
        var missions = BehaviorRelay<[SampleMission]>(value: []) // 뷰에 반영되는 샘플 미션 데이터
        var searchText = BehaviorRelay<String>(value: "")
    }
    
    var input = PublishRelay<Input>()
    var output = Output()
    
    var disposeBag = DisposeBag()
    
    private let sampleMissionUseCaseImpl: SampleMissionUseCase
    private var _missions: [SampleMission] = [] // 샘플 미션 JSON 원본 데이터
    
    init(sampleMissionUseCaseImpl: SampleMissionUseCase = SampleMissionUseCaseImpl()) {
        self.sampleMissionUseCaseImpl = sampleMissionUseCaseImpl
        
        bind()
    }
    
    private func bind() {
        input
            .subscribe { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .onAppear:
                    let missions = sampleMissionUseCaseImpl.loadData()
                    output.missions.accept(missions)
                    _missions = missions
                case .searchTextChanged(let searchText):
                    output.searchText.accept(searchText)
                    print("searchText: \(searchText)")
                    searchMission()
                case .didSelectTableViewCell(let mission):
                    print("didSelectTableViewCell: \(mission.title)")
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
}
