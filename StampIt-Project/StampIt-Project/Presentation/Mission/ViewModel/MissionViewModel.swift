//
//  MissionViewModel.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/4/25.
//

import Foundation
import RxSwift
import RxRelay

final class MissionViewModel: MissionViewModelProtocol {
    enum Input {
        case onAppear
    }
    
    struct Output {
        var missions = BehaviorRelay<[SampleMission]>(value: []) // 샘플 미션 JSON 데이터
        var searchText = BehaviorRelay<String>(value: "")
    }
    
    var input = PublishRelay<Input>()
    var output = Output()
    
    var disposeBag = DisposeBag()
    
    private let sampleMissionUseCaseImpl: SampleMissionUseCase
    
    init(sampleMissionUseCaseImpl: SampleMissionUseCase = SampleMissionUseCaseImpl()) {
        self.sampleMissionUseCaseImpl = sampleMissionUseCaseImpl
        
        bindInput()
    }
    
    private func bindInput() {
        input
            .subscribe { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .onAppear:
                    let missions = sampleMissionUseCaseImpl.loadData()
                    output.missions.accept(missions)
                }
            }
            .disposed(by: disposeBag)
    }
}
