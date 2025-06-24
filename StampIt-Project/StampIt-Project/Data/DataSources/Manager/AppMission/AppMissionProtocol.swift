//
//  AppMissionManagerProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

protocol AppMissionManagerProtocol {
    // 기본 조회
    func fetchAppMissions() -> Observable<[AppMissionFirestore]>
    func fetchAppMission(missionId: String) -> Observable<AppMissionFirestore?>
    func fetchAppMissionsByCategory(category: String) -> Observable<[AppMissionFirestore]>
    
    // 관리자 기능 (필요시)
    func createAppMission(_ appMission: AppMissionFirestore) -> Observable<Void>
    func updateAppMission(_ appMission: AppMissionFirestore) -> Observable<Void>
    func deleteAppMission(missionId: String) -> Observable<Void>
    
    // 캐싱 관련
    func fetchAppMissionsOnce() -> Observable<[AppMissionFirestore]>
}
