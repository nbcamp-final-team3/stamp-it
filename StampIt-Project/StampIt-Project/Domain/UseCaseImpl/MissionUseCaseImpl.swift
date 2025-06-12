//
//  MissionUseCaseImpl.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/5/25.
//

import Foundation
import RxSwift

struct MissionUseCaseImpl: MissionUseCase {
    private let missionRepositoryImpl: MissionRepository
    
    init(missionRepositoryImpl: MissionRepository = MissionRepositoryImpl()) {
        self.missionRepositoryImpl = missionRepositoryImpl
    }
    
    // 샘플 미션 데이터 로드
    func loadSampleMission() -> Single<[SampleMission]> {
        missionRepositoryImpl.loadSampleMission()
    }
    
    // 멤버 데이터 패치
    func fetchMembers(ofGroup groupID: String) -> Observable<[Member]> {
        missionRepositoryImpl.fetchMembers(ofGroup: groupID)
    }
    
    // 현재 로그인된 사용자의 정보 가져오기
    func getCurrentUser() -> Observable<User?> {
        missionRepositoryImpl.getCurrentUser()
    }
    
    // 새 미션 생성
    func createMission(groupId: String, mission: Mission) -> Observable<Void> {
        missionRepositoryImpl.createMission(groupId: groupId, mission: mission)
    }
}
