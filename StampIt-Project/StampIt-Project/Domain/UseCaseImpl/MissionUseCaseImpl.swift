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
    
    init(missionRepositoryImpl: MissionRepository) {
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
    
    // 미션 1개 패치
    func fetchMission(with id: String) -> Observable<MissionUI?> {
        missionRepositoryImpl.fetchMission(widh: id)
            .map { $0?.toPresentation() }
    }
    
    // 코어데이터 샘플 미션을 패치
    func fetchSampleMission() -> [SampleMission] {
        missionRepositoryImpl.fetchSampleMission()
    }
    
    // 코어데이터 특정 샘플 미션을 패치
    func fetchSampleMission(withId missionId: String) -> [SampleMission] {
        missionRepositoryImpl.fetchSampleMission(withId: missionId)
    }
    
    // 코어데이터 샘플 미션 업데이트
    func updateSampleMission(mission: SampleMission) {
        missionRepositoryImpl.updateSampleMission(mission: mission)
    }
}
