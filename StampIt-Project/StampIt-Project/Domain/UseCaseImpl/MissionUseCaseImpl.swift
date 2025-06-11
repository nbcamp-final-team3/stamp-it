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
    
    /// 샘플 미션 데이터 로드
    /// - Returns: 샘플 미션 JSON 데이터(총 100개)
    func loadSampleMission() -> Single<[SampleMission]> {
        missionRepositoryImpl.loadSampleMission()
    }
    
    /// 멤버 데이터 패치
    /// - Parameter groupID: getCurrentGroupID()를 호출하여 groupID를 얻을 수 있음
    /// - Returns: 도메인 레이어 멤버 모델
    func fetchMembers(ofGroup groupID: String) -> Observable<[Member]> {
        missionRepositoryImpl.fetchMembers(ofGroup: groupID)
    }
    
    /// 현재 사용자의 그룹 ID 반환
    /// - Returns: 그룹 ID String
    func getCurrentGroupID() -> Observable<String> {
        missionRepositoryImpl.getCurrentGroupID()
    }
}
