//
//  StampManagerProtocol.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import RxSwift
import Foundation

// MARK: - StampManager Protocol (기존 FirestoreManager 메서드 통합)
protocol StampManagerProtocol: FullCRUDRepository where Entity == StampFirestore, ID == String, Query == StampQuery {
    // 기본 CRUD
    func addStamp(_ stamp: StampFirestore) -> Observable<Void>
    func updateStamp(_ stamp: StampFirestore) -> Observable<Void>
    
    // 조회 메서드들 (기존 FirestoreManager 메서드)
    func fetchStamps(userId: String, month: String) -> Observable<[StampFirestore]>
    func fetchStampsByPin(userId: String, pinNumber: Int) -> Observable<[StampFirestore]>
    func fetchStampCount(userId: String) -> Observable<Int>
    func fetchGroupStamps(groupId: String, month: String) -> Observable<[StampFirestore]>
    func fetchAllUserStamps(userId: String) -> Observable<[StampFirestore]>
    
    func observeStampCount(userId: String) -> Observable<Int>
    
    // 삭제 메서드들 (기존 FirestoreManager 메서드)
    func deleteStamp(missionId: String) -> Observable<Void>
    func deleteUserStamps(userId: String, groupId: String) -> Observable<Void>
    func deleteUserStamps(userId: String) -> Observable<Void>
    func deleteGroupStamps(groupId: String) -> Observable<Void>
    
    // TODO: 미션 완료 시 스티커 생성 (CURD 리팩토링 중 Stamp 리팩토링 할 때 비즈니스 로직으로 레포에 내릴 예정)
    func createStampFromMission(
        userId: String,
        groupId: String,
        missionTitle: String,
        maxStamps: Int,
        stampType: String,
        missionId: String,
        assignedBy: String
    ) -> Observable<Void> 
}
