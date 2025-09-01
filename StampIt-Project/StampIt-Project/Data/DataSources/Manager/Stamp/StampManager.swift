//
//  StampManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import RxSwift

// MARK: - StampManager Implementation
final class StampManager: StampManagerProtocol {
    
    typealias Entity = StampFirestore
    typealias ID = String
    typealias Query = StampQuery
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    var stampCollection: CollectionReference {
        return db.collection("stickers")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - FullCRUDRepository 프로토콜 구현
    func fetch(id: String) -> Observable<StampFirestore?> {
        return Observable.create { observer in
            self.stampCollection.document(id)
                .getDocument(source: .server) { documentSnapshot, error in
                    if let error = error {
                        observer.onError(StampError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    
                    do {
                        let stamp = try document.data(as: StampFirestore.self)
                        observer.onNext(stamp)
                        observer.onCompleted()
                    } catch {
                        observer.onError(StampError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    func observe(id: String) -> Observable<StampFirestore?> {
        return Observable.create { observer in
            let listener = self.stampCollection.document(id)
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        observer.onError(StampError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onNext(nil)
                        return
                    }
                    
                    do {
                        let stamp = try document.data(as: StampFirestore.self)
                        observer.onNext(stamp)
                    } catch {
                        observer.onError(StampError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    func create(_ entity: StampFirestore) -> Observable<Void> {
        return addStamp(entity)
    }
    
    func update(id: String, entity: StampFirestore) -> Observable<Void> {
        guard id == entity.documentID else {
            return Observable.error(StampError.invalidInput("ID 불일치"))
        }
        return updateStamp(entity)
    }
    
    func updateFields(id: String, fields: [String: Any]) -> Observable<Void> {
        return Observable.create { observer in
            self.stampCollection.document(id).updateData(fields) { error in
                if let error = error {
                    observer.onError(StampError.updateFailed(error.localizedDescription))
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
            self.stampCollection.document(id).delete { error in
                if let error = error {
                    observer.onError(StampError.deleteFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchList(query: StampQuery) -> Observable<[StampFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.stampCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            firestoreQuery.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(StampError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                do {
                    let stamps = try documents.compactMap { document in
                        try document.data(as: StampFirestore.self)
                    }
                    observer.onNext(stamps)
                    observer.onCompleted()
                } catch {
                    observer.onError(StampError.decodingFailed(error.localizedDescription))
                }
            }
            return Disposables.create()
        }
    }

    func observeList(query: StampQuery) -> Observable<[StampFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.stampCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            let listener = firestoreQuery.addSnapshotListener { snapshot, error in
                if let error = error {
                    observer.onError(StampError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    return
                }
                
                do {
                    let stamps = try documents.compactMap { document in
                        try document.data(as: StampFirestore.self)
                    }
                    observer.onNext(stamps)
                } catch {
                    observer.onError(StampError.decodingFailed(error.localizedDescription))
                }
            }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    // MARK: - Private Helper
    private func applyQueryConditions(_ query: FirebaseFirestore.Query, query stampQuery: StampQuery) -> FirebaseFirestore.Query {
        var result = query
        
        if let stampId = stampQuery.stampId, !stampId.isEmpty {
            result = result.whereField("stickerId", in: stampId)
        }
        
        if let userId = stampQuery.userId, !userId.isEmpty {
            result = result.whereField("userId", in: userId)
        }
        
        if let groupId = stampQuery.groupId, !groupId.isEmpty {
            result = result.whereField("groupId", in: groupId)
        }

        if let missionId = stampQuery.missionId, !missionId.isEmpty {
            result = result.whereField("missionId", in: missionId)
        }

        if let month = stampQuery.month, !month.isEmpty {
            result = result.whereField("month", in: month)
        }
        
        if let pinNumber = stampQuery.pinNumber, !pinNumber.isEmpty {
            result = result.whereField("pinNumber", in: pinNumber)
        }
        
        if let type = stampQuery.type, !type.isEmpty {
            result = result.whereField("type", in: type)
        }
        
        if let createdAt = stampQuery.createdAt {
            result = result.whereField("createdAt", isGreaterThan: Timestamp(date: createdAt))
        }
        
        if let orderBy = stampQuery.orderBy {
            result = result.order(by: orderBy.field, descending: orderBy.descending)
        }
        
        if let limit = stampQuery.limit {
            result = result.limit(to: limit)
        }
        
        return result
    }
    
    // MARK: - 기존 FirestoreManager 메서드들 (하위 호환성)
    
    /// 새 스티커 추가
    func addStamp(_ stamp: StampFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.stampCollection.document(stamp.documentID)
                    .setData(from: stamp) { error in
                        if let error = error {
                            observer.onError(StampError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(StampError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 스티커 정보 업데이트 (타입 변경 등)
    func updateStamp(_ stamp: StampFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.stampCollection.document(stamp.documentID)
                    .setData(from: stamp, merge: true) { error in
                        if let error = error {
                            observer.onError(StampError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(StampError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 특정 사용자의 월별 스티커 조회
    func fetchStamps(userId: String, month: String) -> Observable<[StampFirestore]> {
        return observeList(query: .byUserAndMonth(userId, month: month))
    }
    
    /// 특정 사용자의 핀번호별 스티커 조회 (이전 스티커판용)
    func fetchStampsByPin(userId: String, pinNumber: Int) -> Observable<[StampFirestore]> {
        return observeList(query: .byUserAndPin(userId, pinNumber: pinNumber))
    }
    
    /// 특정 사용자의 현재 스티커 개수 조회 (핀번호 계산용)
    func fetchStampCount(userId: String) -> Observable<Int> {
        return fetchList(query: .byUser(userId))
            .map { $0.count }
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
    }
    
    /// 실시간 카운트(스티커 추가/삭제 실시간 반영)
    func observeStampCount(userId: String) -> Observable<Int> {
        return observeList(query: .byUserAndDescCreatedAfter(userId))
            .map { $0.count }
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
    }
    
    /// 특정 그룹의 모든 스티커 조회 (그룹 랭킹용-홈)
    func fetchGroupStamps(groupId: String, month: String) -> Observable<[StampFirestore]> {
        return observeList(query: .byGroupAndMonth(groupId, month: month))
    }
    
    /// 특정 사용자의 모든 스티커 조회 (전체 기록용-마이페이지)
    func fetchAllUserStamps(userId: String) -> Observable<[StampFirestore]> {
        return observeList(query: .byUser(userId))
    }

    /// 특정 미션에 대한 스티커 삭제 (미션완료 취소용)
    func deleteStamp(missionId: String) -> Observable<Void> {
        return fetchList(query: .byMission(missionId))
            .flatMap { [weak self] stamps -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(StampError.fetchFailed("StampManager 인스턴스가 없습니다"))
                }

                let deleteObservables = stamps.map { stamp in
                    self.delete(id: stamp.documentID)
                }
                return Observable.zip(deleteObservables).map { _ in () }
            }
    }

    /// 특정 그룹에서 사용자 스티커 삭제 (그룹 탈퇴용)
    func deleteUserStamps(userId: String, groupId: String) -> Observable<Void> {
        return fetchList(query: StampQuery(
            stampId: nil,
            userId: [userId],
            groupId: [groupId],
            missionId: nil,
            month: nil,
            pinNumber: nil,
            type: nil,
            createdAt: nil,
            orderBy: nil,
            limit: nil
        ))
        .flatMap { [weak self] stamps -> Observable<Void> in
            guard let self = self else {
                return Observable.error(StampError.fetchFailed("StampManager 인스턴스가 없습니다"))
            }
            
            // 빈 배열 처리
            guard !stamps.isEmpty else {
                return Observable.just(())
            }
            
            let deleteObservables = stamps.map { stamp in
                self.delete(id: stamp.documentID)
            }
            
            return Observable.zip(deleteObservables).map { _ in () }
        }
    }

    /// 사용자의 모든 스티커 삭제 (서비스 탈퇴용)
    func deleteUserStamps(userId: String) -> Observable<Void> {
        return fetchList(query: StampQuery(
            stampId: nil,
            userId: [userId],
            groupId: nil,  // 모든 그룹
            missionId: nil,
            month: nil,
            pinNumber: nil,
            type: nil,
            createdAt: nil,
            orderBy: nil,
            limit: nil
        ))
        .flatMap { [weak self] stamps -> Observable<Void> in
            guard let self = self else {
                return Observable.error(StampError.fetchFailed("StampManager 인스턴스가 없습니다"))
            }
            
            // 빈 배열 처리
            guard !stamps.isEmpty else {
                return Observable.just(())
            }
            
            let deleteObservables = stamps.map { stamp in
                self.delete(id: stamp.documentID)
            }
            
            return Observable.zip(deleteObservables).map { _ in () }
        }
    }

    /// 특정 그룹의 모든 스티커 삭제 (그룹 삭제 시 사용)
    func deleteGroupStamps(groupId: String) -> Observable<Void> {
        return fetchList(query: .byGroup(groupId))
            .flatMap { [weak self] stamps -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(StampError.fetchFailed("StampManager 인스턴스가 없습니다"))
                }
                
                // 빈 배열 처리
                guard !stamps.isEmpty else {
                    return Observable.just(())
                }
                
                let deleteObservables = stamps.map { stamp in
                    self.delete(id: stamp.documentID)
                }
                
                return Observable.zip(deleteObservables).map { _ in () }
            }
    }
    
    /// 미션 완료 시 자동 스티커 생성 (핀번호 자동 계산)
    func createStampFromMission(
        userId: String,
        groupId: String,
        missionTitle: String,
        maxStamps: Int,
        stampType: String,
        missionId: String,
        assignedBy: String
    ) -> Observable<Void> {
        return fetchStampCount(userId: userId)
            .flatMap { [weak self] currentCount -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(StampError.fetchFailed("StampManager 인스턴스가 없습니다"))
                }
                
                let now = Date()
                let calendar = Calendar.current
                let month = String(format: "%04d-%02d",
                                   calendar.component(.year, from: now),
                                   calendar.component(.month, from: now))
                
                // 핀번호 계산: 1~30개 = 핀1, 31~60개 = 핀2, ...
                let pinNumber = (currentCount / 30) + 1
                
                let stamp = StampFirestore(
                    stickerId: UUID().uuidString,
                    userId: userId,
                    groupId: groupId,
                    month: month,
                    type: stampType,
                    pinNumber: pinNumber,
                    createdAt: Timestamp(date: now),
                    missionId: missionId,
                    maxStickers: maxStamps,
                    assignedBy: assignedBy
                )
                
                return self.addStamp(stamp)
            }
    }
}
