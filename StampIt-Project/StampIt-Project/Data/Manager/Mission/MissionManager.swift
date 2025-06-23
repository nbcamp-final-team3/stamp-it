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

final class MissionManager: MissionManagerProtocol {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    private var missionsCollection: CollectionReference {
        return db.collection("missions")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - Mission Operations
    
    /// 그룹 미션 목록 실시간 조회
    func fetchMissions(groupId: String) -> Observable<[MissionFirestore]> {
        return Observable.create { observer in
            let listener = self.missionsCollection
                .whereField("groupId", isEqualTo: groupId)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(MissionError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let missions = try documents.compactMap { document -> MissionFirestore? in
                            return try document.data(as: MissionFirestore.self)
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
    
    /// 특정 미션 조회
    func fetchMission(missionId: String) -> Observable<MissionFirestore?> {
        return Observable.create { observer in
            self.missionsCollection.document(missionId)
                .getDocument { documentSnapshot, error in
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
    
    /// 새 미션 생성
    func createMission(_ mission: MissionFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.missionsCollection.document(mission.documentID)
                    .setData(from: mission) { error in
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
    
    /// 미션 정보 업데이트
    func updateMission(_ mission: MissionFirestore) -> Observable<MissionFirestore> {
        return Observable.create { observer in
            do {
                try self.missionsCollection.document(mission.documentID)
                    .setData(from: mission, merge: true) { error in
                        if let error = error {
                            observer.onError(MissionError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(mission)
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(MissionError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 미션 삭제
    func deleteMission(missionId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.missionsCollection.document(missionId)
                .delete { error in
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
    
    /// 할당된 미션 목록 조회
    func fetchMissions(to assigneeId: String?, by assignerId: String?, ofGroup groupId: String) -> Observable<[MissionFirestore]> {
        return Observable.create { observer in
            var query = self.missionsCollection.whereField("groupId", isEqualTo: groupId)
            
            if let assigneeId = assigneeId {
                query = query.whereField("assignedTo", isEqualTo: assigneeId)
            }
            
            if let assignerId = assignerId {
                query = query.whereField("assignedBy", isEqualTo: assignerId)
            }
            
            let listener = query.addSnapshotListener { querySnapshot, error in
                if let error = error {
                    observer.onError(MissionError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    observer.onNext([])
                    return
                }
                
                do {
                    let missions = try documents.compactMap { document -> MissionFirestore? in
                        return try document.data(as: MissionFirestore.self)
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
    
    /// 상태별 미션 조회
    func fetchMissionsByStatus(groupId: String, status: String) -> Observable<[MissionFirestore]> {
        return Observable.create { observer in
            let listener = self.missionsCollection
                .whereField("groupId", isEqualTo: groupId)
                .whereField("status", isEqualTo: status)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(MissionError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let missions = try documents.compactMap { document -> MissionFirestore? in
                            return try document.data(as: MissionFirestore.self)
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
    
    /// 사용자별 미션 조회
    func fetchMissionsByUser(userId: String, groupId: String) -> Observable<[MissionFirestore]> {
        return Observable.create { observer in
            let listener = self.missionsCollection
                .whereField("groupId", isEqualTo: groupId)
                .whereField("assignedTo", isEqualTo: userId)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(MissionError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let missions = try documents.compactMap { document -> MissionFirestore? in
                            return try document.data(as: MissionFirestore.self)
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
    
    /// 미션 상태 업데이트
    func updateMissionStatus(missionId: String, status: String) -> Observable<Void> {
        return Observable.create { observer in
            self.missionsCollection.document(missionId).updateData([
                "status": status
            ]) { error in
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
    
    /// 특정 사용자 관련 미션 삭제 (유저 탈퇴 시 사용)
    func deleteUserMissions(userId: String, groupId: String) -> Observable<Void> {
        return Observable.create { observer in
            // 사용자가 할당받은 미션과 할당한 미션 모두 삭제
            let assignedToQuery = self.missionsCollection
                .whereField("groupId", isEqualTo: groupId)
                .whereField("assignedTo", isEqualTo: userId)
            
            let assignedByQuery = self.missionsCollection
                .whereField("groupId", isEqualTo: groupId)
                .whereField("assignedBy", isEqualTo: userId)
            
            assignedToQuery.getDocuments { querySnapshot1, error1 in
                if let error1 = error1 {
                    observer.onError(MissionError.deleteFailed(error1.localizedDescription))
                    return
                }
                
                assignedByQuery.getDocuments { querySnapshot2, error2 in
                    if let error2 = error2 {
                        observer.onError(MissionError.deleteFailed(error2.localizedDescription))
                        return
                    }
                    
                    let batch = Firestore.firestore().batch()
                    
                    // 할당받은 미션 삭제
                    querySnapshot1?.documents.forEach { document in
                        batch.deleteDocument(document.reference)
                    }
                    
                    // 할당한 미션 삭제
                    querySnapshot2?.documents.forEach { document in
                        batch.deleteDocument(document.reference)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            observer.onError(MissionError.deleteFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    /// 특정 그룹의 모든 미션 삭제
    func deleteGroupMissions(groupId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.missionsCollection
                .whereField("groupId", isEqualTo: groupId)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(MissionError.deleteFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext(())
                        observer.onCompleted()
                        return
                    }
                    
                    let batch = Firestore.firestore().batch()
                    documents.forEach { document in
                        batch.deleteDocument(document.reference)
                    }
                    
                    batch.commit { error in
                        if let error = error {
                            observer.onError(MissionError.deleteFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                }
            return Disposables.create()
        }
    }
}
