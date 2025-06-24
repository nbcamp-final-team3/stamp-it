//
//  MissionManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import RxSwift

// MARK: - MissionManager Implementation (✅ 완전 리팩토링)
final class MissionManager: MissionManagerProtocol {
    typealias Entity = MissionFirestore
    typealias ID = String
    typealias Query = MissionQuery
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    var missionCollection: CollectionReference {
        return db.collection("missions")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - FullCRUDRepository 프로토콜 구현
    func fetch(id: String) -> Observable<MissionFirestore?> {
        return Observable.create { observer in
            self.missionCollection.document(id)
                .getDocument(source: .server) { documentSnapshot, error in
                    if let error = error {
                        observer.onError(MissionError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    
                    do {
                        let mission = try document.data(as: MissionFirestore.self)
                        observer.onNext(mission)
                        observer.onCompleted()
                    } catch {
                        observer.onError(MissionError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    func observe(id: String) -> Observable<MissionFirestore?> {
        return Observable.create { observer in
            let listener = self.missionCollection.document(id)
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        observer.onError(MissionError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onNext(nil)
                        return
                    }
                    
                    do {
                        let mission = try document.data(as: MissionFirestore.self)
                        observer.onNext(mission)
                    } catch {
                        observer.onError(MissionError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    func create(_ entity: MissionFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.missionCollection.document(entity.documentID)
                    .setData(from: entity) { error in
                        if let error = error {
                            observer.onError(MissionError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(MissionError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    func update(id: String, entity: MissionFirestore) -> Observable<Void> {
        guard id == entity.documentID else {
            return Observable.error(MissionError.invalidInput("ID 불일치"))
        }
        
        return Observable.create { observer in
            do {
                try self.missionCollection.document(entity.documentID)
                    .setData(from: entity, merge: true) { error in
                        if let error = error {
                            observer.onError(MissionError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(MissionError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    func updateFields(id: String, fields: [String: Any]) -> Observable<Void> {
        return Observable.create { observer in
            self.missionCollection.document(id).updateData(fields) { error in
                if let error = error {
                    observer.onError(MissionError.updateFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func delete(id: String) -> Observable<Void> {
        return Observable.create { observer in
            self.missionCollection.document(id).delete { error in
                if let error = error {
                    observer.onError(MissionError.deleteFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchList(query: MissionQuery) -> Observable<[MissionFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.missionCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            firestoreQuery.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(MissionError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                do {
                    let missions = try documents.compactMap { document in
                        try document.data(as: MissionFirestore.self)
                    }
                    observer.onNext(missions)
                    observer.onCompleted()
                } catch {
                    observer.onError(MissionError.decodingFailed(error.localizedDescription))
                }
            }
            return Disposables.create()
        }
    }
    
    func observeList(query: MissionQuery) -> Observable<[MissionFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.missionCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            let listener = firestoreQuery.addSnapshotListener { snapshot, error in
                if let error = error {
                    observer.onError(MissionError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    return
                }
                
                do {
                    let missions = try documents.compactMap { document in
                        try document.data(as: MissionFirestore.self)
                    }
                    observer.onNext(missions)
                } catch {
                    observer.onError(MissionError.decodingFailed(error.localizedDescription))
                }
            }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    // MARK: - Private Helper
    private func applyQueryConditions(_ query: FirebaseFirestore.Query, query missionQuery: MissionQuery) -> FirebaseFirestore.Query {
        var result = query
        
        if let missionIds = missionQuery.missionIds, !missionIds.isEmpty {
            result = result.whereField("missionId", in: missionIds)
        }
        
        if let groupIds = missionQuery.groupIds, !groupIds.isEmpty {
            result = result.whereField("groupId", in: groupIds)
        }
        
        if let assigneeIds = missionQuery.assigneeIds, !assigneeIds.isEmpty {
            result = result.whereField("assignedTo", in: assigneeIds)
        }
        
        if let assignerIds = missionQuery.assignerIds, !assignerIds.isEmpty {
            result = result.whereField("assignedBy", in: assignerIds)
        }
        
        if let isCompleted = missionQuery.isCompleted {
            result = result.whereField("isCompleted", isEqualTo: isCompleted)
        }
        
        if let createdAfter = missionQuery.createdAfter {
            result = result.whereField("createdAt", isGreaterThan: Timestamp(date: createdAfter))
        }
        
        if let dueDate = missionQuery.dueDate {
            result = result.whereField("dueDate", isLessThanOrEqualTo: Timestamp(date: dueDate))
        }
        
        if let orderBy = missionQuery.orderBy {
            result = result.order(by: orderBy.field, descending: orderBy.descending)
        }
        
        if let limit = missionQuery.limit {
            result = result.limit(to: limit)
        }
        
        return result
    }
    
    // MARK: - 기존 FirestoreManager 메서드들 (하위 호환성)
    
    /// 그룹 미션 목록 실시간 조회
    func fetchMissions(groupId: String) -> Observable<[MissionFirestore]> {
        return observeList(query: .byGroup(groupId))
    }
    
    /// 할당된 미션 목록 조회
    func fetchMissions(to assigneeId: String?, by assignerId: String?, ofGroup groupId: String) -> Observable<[MissionFirestore]> {
        let query: MissionQuery
        
        if let assigneeId = assigneeId {
            query = .byAssignee(assigneeId, groupId: groupId)
        } else if let assignerId = assignerId {
            query = .byAssigner(assignerId, groupId: groupId)
        } else {
            query = .byGroup(groupId)
        }
        
        return observeList(query: query)
    }
    
    /// 새 미션 생성
    func createMission(groupId: String, mission: MissionFirestore) -> Observable<Void> {
        return create(mission)
    }
    
    /// 미션 정보 업데이트
    func updateMission(groupId: String, mission: MissionFirestore) -> Observable<MissionFirestore> {
        return update(id: mission.documentID, entity: mission)
            .map { _ in mission }
    }
    
    /// 미션 삭제
    func deleteMission(groupId: String, missionId: String) -> Observable<Void> {
        return delete(id: missionId)
    }
    
    /// 특정 사용자 관련 미션 삭제 (유저 탈퇴 시 사용)
    func deleteUserMissions(userId: String, groupId: String) -> Observable<Void> {
        return Observable.create { observer in
            // 사용자가 할당받은 미션 조회
            self.fetchList(query: .byAssignee(userId, groupId: groupId))
                .flatMap { assignedMissions -> Observable<Void> in
                    // 사용자가 할당한 미션 조회
                    return self.fetchList(query: .byAssigner(userId, groupId: groupId))
                        .map { assignedByMissions in
                            return assignedMissions + assignedByMissions
                        }
                }
                .flatMap { allMissions -> Observable<Void> in
                    let deleteObservables = allMissions.map { mission in
                        self.delete(id: mission.documentID)
                    }
                    return Observable.zip(deleteObservables).map { _ in () }
                }
                .subscribe(
                    onNext: {
                        observer.onNext(())
                        observer.onCompleted()
                    },
                    onError: { error in
                        observer.onError(MissionError.deleteFailed(error.localizedDescription))
                    }
                )
                .disposed(by: DisposeBag())
            
            return Disposables.create()
        }
    }
    
    /// 특정 그룹의 모든 미션 삭제 (그룹 삭제 시 사용)
    func deleteGroupMissions(groupId: String) -> Observable<Void> {
        return fetchList(query: .byGroup(groupId))
            .flatMap { [weak self] missions -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(MissionError.fetchFailed("MissionManager 인스턴스가 없습니다"))
                }
                
                let deleteObservables = missions.map { mission in
                    self.delete(id: mission.documentID)
                }
                return Observable.zip(deleteObservables).map { _ in () }
            }
    }
}
