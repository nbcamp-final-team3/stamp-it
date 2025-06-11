//
//  MissionUseCaseImpl.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/5/25.
//

import Foundation

struct MissionUseCaseImpl: MissionUseCase {
    private let missionRepositoryImpl: MissionRepository
    
    init(missionRepositoryImpl: MissionRepository = MissionRepositoryImpl()) {
        self.missionRepositoryImpl = missionRepositoryImpl
    }
    
    func loadSampleMission() -> [SampleMission] {
        missionRepositoryImpl.loadSampleMission()
    }
}
