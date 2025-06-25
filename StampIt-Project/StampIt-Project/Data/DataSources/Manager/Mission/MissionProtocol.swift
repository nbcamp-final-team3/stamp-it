//
//  MissionProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

// MARK: - MissionManager Protocol (기존 FirestoreManager 메서드 통합)
protocol MissionManagerProtocol: FullCRUDRepository where Entity == MissionFirestore, ID == String, Query == MissionQuery {
    // 기본 CRUD
    func fetchMissions(groupId: String) -> Observable<[MissionFirestore]>
    func createMission(groupId: String, mission: MissionFirestore) -> Observable<Void>
    func updateMission(groupId: String, mission: MissionFirestore) -> Observable<MissionFirestore>
    func deleteMission(groupId: String, missionId: String) -> Observable<Void>
    
    // 특화 메서드들 (기존 FirestoreManager 메서드)
    func fetchMissions(to assigneeId: String?, by assignerId: String?, ofGroup groupId: String) -> Observable<[MissionFirestore]>
    func deleteUserMissions(userId: String, groupId: String) -> Observable<Void>
    func deleteGroupMissions(groupId: String) -> Observable<Void>
}
