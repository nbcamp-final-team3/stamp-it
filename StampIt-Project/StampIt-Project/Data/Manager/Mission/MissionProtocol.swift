//
//  MissionProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

protocol MissionManagerProtocol {
    // 기본 CRUD
    func fetchMissions(groupId: String) -> Observable<[MissionFirestore]>
    func fetchMission(missionId: String) -> Observable<MissionFirestore?>
    func createMission(_ mission: MissionFirestore) -> Observable<Void>
    func updateMission(_ mission: MissionFirestore) -> Observable<MissionFirestore>
    func deleteMission(missionId: String) -> Observable<Void>
    
    // 조건부 조회
    func fetchMissions(to assigneeId: String?, by assignerId: String?, ofGroup groupId: String) -> Observable<[MissionFirestore]>
    func fetchMissionsByStatus(groupId: String, status: String) -> Observable<[MissionFirestore]>
    func fetchMissionsByUser(userId: String, groupId: String) -> Observable<[MissionFirestore]>
    
    // 상태 업데이트
    func updateMissionStatus(missionId: String, status: String) -> Observable<Void>
    
    // 삭제 관련
    func deleteUserMissions(userId: String, groupId: String) -> Observable<Void>
    func deleteGroupMissions(groupId: String) -> Observable<Void>
}
