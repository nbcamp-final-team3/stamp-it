//
//  MissionUseCase.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/5/25.
//

import Foundation
import RxSwift

protocol MissionUseCase {
    /// 샘플 미션 데이터 로드
    /// - Returns: 샘플 미션 JSON 데이터(총 100개)
    func loadSampleMission() -> Single<[SampleMission]>
    
    /// 멤버 데이터 패치
    /// - Parameter groupID: getCurrentUser() 또는 getCurrentGroupID()를 호출하여 groupID를 얻을 수 있음
    /// - Returns: 도메인 레이어 멤버 모델
    func fetchMembers(ofGroup groupID: String) -> Observable<[Member]>
    
    /// 현재 로그인된 사용자의 정보를 그룹 정보와 함께 조회
    /// - Returns: 도메인 레이어 유저 모델(옵셔널)
    func getCurrentUser() -> Observable<User?>
    
    /// 새 미션 생성
    /// - Parameters:
    ///   - groupId: getCurrentGroupID()를 호출하여 groupID를 얻을 수 있음
    ///   - mission: 도메인 레이어 Mission 모델
    /// - Returns: Observable(Void)
    func createMission(groupId: String, mission: Mission) -> Observable<Void>
}
