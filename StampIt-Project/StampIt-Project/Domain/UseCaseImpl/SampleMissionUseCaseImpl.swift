//
//  SampleMissionUseCaseImpl.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/5/25.
//

import Foundation

struct SampleMissionUseCaseImpl: SampleMissionUseCase {
    private let sampleMissionRepositoryImpl: SampleMissionRepository
    
    init(sampleMissionRepositoryImpl: SampleMissionRepository = SampleMissionRepositoryImpl()) {
        self.sampleMissionRepositoryImpl = sampleMissionRepositoryImpl
    }
    
    func loadData() -> [SampleMission] {
        sampleMissionRepositoryImpl.loadData()
    }
}
