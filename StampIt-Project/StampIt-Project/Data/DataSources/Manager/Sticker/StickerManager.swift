//
//  StickerManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

import Foundation
import FirebaseFirestore
import Firebase
import RxSwift

// MARK: - StickerManager Implementation
final class StickerManager: StickerManagerProtocol {
    
    typealias Entity = StickerFirestore
    typealias ID = String
    typealias Query = StickerQuery
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    var stickerCollection: CollectionReference {
        return db.collection("stickers")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - FullCRUDRepository 프로토콜 구현
    func fetch(id: String) -> Observable<StickerFirestore?> {
        return Observable.create { observer in
            self.stickerCollection.document(id)
                .getDocument(source: .server) { documentSnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    
                    do {
                        let sticker = try document.data(as: StickerFirestore.self)
                        observer.onNext(sticker)
                        observer.onCompleted()
                    } catch {
                        observer.onError(StickerError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    func observe(id: String) -> Observable<StickerFirestore?> {
        return Observable.create { observer in
            let listener = self.stickerCollection.document(id)
                .addSnapshotListener { documentSnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onNext(nil)
                        return
                    }
                    
                    do {
                        let sticker = try document.data(as: StickerFirestore.self)
                        observer.onNext(sticker)
                    } catch {
                        observer.onError(StickerError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    func create(_ entity: StickerFirestore) -> Observable<Void> {
        return addSticker(entity)
    }
    
    func update(id: String, entity: StickerFirestore) -> Observable<Void> {
        guard id == entity.documentID else {
            return Observable.error(StickerError.invalidInput("ID 불일치"))
        }
        return updateSticker(entity)
    }
    
    func updateFields(id: String, fields: [String: Any]) -> Observable<Void> {
        return Observable.create { observer in
            self.stickerCollection.document(id).updateData(fields) { error in
                if let error = error {
                    observer.onError(StickerError.updateFailed(error.localizedDescription))
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
            self.stickerCollection.document(id).delete { error in
                if let error = error {
                    observer.onError(StickerError.deleteFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    func fetchList(query: StickerQuery) -> Observable<[StickerFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.stickerCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            firestoreQuery.getDocuments { snapshot, error in
                if let error = error {
                    observer.onError(StickerError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    observer.onCompleted()
                    return
                }
                
                do {
                    let stickers = try documents.compactMap { document in
                        try document.data(as: StickerFirestore.self)
                    }
                    observer.onNext(stickers)
                    observer.onCompleted()
                } catch {
                    observer.onError(StickerError.decodingFailed(error.localizedDescription))
                }
            }
            return Disposables.create()
        }
    }

    func observeList(query: StickerQuery) -> Observable<[StickerFirestore]> {
        return Observable.create { observer in
            var firestoreQuery: FirebaseFirestore.Query = self.stickerCollection
            
            // 쿼리 조건 적용
            firestoreQuery = self.applyQueryConditions(firestoreQuery, query: query)
            
            let listener = firestoreQuery.addSnapshotListener { snapshot, error in
                if let error = error {
                    observer.onError(StickerError.fetchFailed(error.localizedDescription))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    return
                }
                
                do {
                    let stickers = try documents.compactMap { document in
                        try document.data(as: StickerFirestore.self)
                    }
                    observer.onNext(stickers)
                } catch {
                    observer.onError(StickerError.decodingFailed(error.localizedDescription))
                }
            }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    // MARK: - Private Helper
    private func applyQueryConditions(_ query: FirebaseFirestore.Query, query stickerQuery: StickerQuery) -> FirebaseFirestore.Query {
        var result = query
        
        if let stickerId = stickerQuery.stickerId, !stickerId.isEmpty {
            result = result.whereField("stickerId", in: stickerId)
        }
        
        if let userId = stickerQuery.userId, !userId.isEmpty {
            result = result.whereField("userId", in: userId)
        }
        
        if let groupId = stickerQuery.groupId, !groupId.isEmpty {
            result = result.whereField("groupId", in: groupId)
        }

        if let missionId = stickerQuery.missionId, !missionId.isEmpty {
            result = result.whereField("missionId", in: missionId)
        }

        if let month = stickerQuery.month, !month.isEmpty {
            result = result.whereField("month", in: month)
        }
        
        if let pinNumber = stickerQuery.pinNumber, !pinNumber.isEmpty {
            result = result.whereField("pinNumber", in: pinNumber)
        }
        
        if let type = stickerQuery.type, !type.isEmpty {
            result = result.whereField("type", in: type)
        }
        
        if let createdAt = stickerQuery.createdAt {
            result = result.whereField("createdAt", isGreaterThan: Timestamp(date: createdAt))
        }
        
        if let orderBy = stickerQuery.orderBy {
            result = result.order(by: orderBy.field, descending: orderBy.descending)
        }
        
        if let limit = stickerQuery.limit {
            result = result.limit(to: limit)
        }
        
        return result
    }
    
    // MARK: - 기존 FirestoreManager 메서드들 (하위 호환성)
    
    /// 새 스티커 추가
    func addSticker(_ sticker: StickerFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.stickerCollection.document(sticker.documentID)
                    .setData(from: sticker) { error in
                        if let error = error {
                            observer.onError(StickerError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(StickerError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 스티커 정보 업데이트 (타입 변경 등)
    func updateSticker(_ sticker: StickerFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.stickerCollection.document(sticker.documentID)
                    .setData(from: sticker, merge: true) { error in
                        if let error = error {
                            observer.onError(StickerError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(StickerError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 특정 사용자의 월별 스티커 조회
    func fetchStickers(userId: String, month: String) -> Observable<[StickerFirestore]> {
        return observeList(query: .byUserAndMonth(userId, month: month))
    }
    
    /// 특정 사용자의 핀번호별 스티커 조회 (이전 스티커판용)
    func fetchStickersByPin(userId: String, pinNumber: Int) -> Observable<[StickerFirestore]> {
        return observeList(query: .byUserAndPin(userId, pinNumber: pinNumber))
    }
    
    /// 특정 사용자의 현재 스티커 개수 조회 (핀번호 계산용)
    func fetchStickerCount(userId: String) -> Observable<Int> {
        return fetchList(query: .byUser(userId))
            .map { $0.count }
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
    }
    
    /// 실시간 카운트(스티커 추가/삭제 실시간 반영)
    func observeStickerCount(userId: String) -> Observable<Int> {
        return observeList(query: .byUserAndDescCreatedAfter(userId))
            .map { $0.count }
            .distinctUntilChanged()
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
    }
    
    /// 특정 그룹의 모든 스티커 조회 (그룹 랭킹용-홈)
    func fetchGroupStickers(groupId: String, month: String) -> Observable<[StickerFirestore]> {
        return observeList(query: .byGroupAndMonth(groupId, month: month))
    }
    
    /// 특정 사용자의 모든 스티커 조회 (전체 기록용-마이페이지)
    func fetchAllUserStickers(userId: String) -> Observable<[StickerFirestore]> {
        return observeList(query: .byUser(userId))
    }

    /// 특정 미션에 대한 스티커 삭제 (미션완료 취소용)
    func deleteSticker(missionId: String) -> Observable<Void> {
        return fetchList(query: .byMission(missionId))
            .flatMap { [weak self] stickers -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(StickerError.fetchFailed("StickerManager 인스턴스가 없습니다"))
                }

                let deleteObservables = stickers.map { sticker in
                    self.delete(id: sticker.documentID)
                }
                return Observable.zip(deleteObservables).map { _ in () }
            }
    }

    /// 특정 그룹에서 사용자 스티커 삭제 (그룹 탈퇴용)
    func deleteUserStickers(userId: String, groupId: String) -> Observable<Void> {
        return fetchList(query: StickerQuery(
            stickerId: nil,
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
        .flatMap { [weak self] stickers -> Observable<Void> in
            guard let self = self else {
                return Observable.error(StickerError.fetchFailed("StickerManager 인스턴스가 없습니다"))
            }
            
            let deleteObservables = stickers.map { sticker in
                self.delete(id: sticker.documentID)
            }
            return Observable.zip(deleteObservables).map { _ in () }
        }
    }
    
    /// 사용자의 모든 스티커 삭제 (서비스 탈퇴용)
    func deleteUserStickers(userId: String) -> Observable<Void> {
        return fetchList(query: StickerQuery(
            stickerId: nil,
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
        .flatMap { [weak self] stickers -> Observable<Void> in
            guard let self = self else {
                return Observable.error(StickerError.fetchFailed("StickerManager 인스턴스가 없습니다"))
            }
            
            // 빈 배열 처리
            guard !stickers.isEmpty else {
                return Observable.just(())
            }
            
            let deleteObservables = stickers.map { sticker in
                self.delete(id: sticker.documentID)
            }
            
            return Observable.zip(deleteObservables)
                .map { _ in () }
        }
    }
    
    /// 특정 그룹의 모든 스티커 삭제 (그룹 삭제 시 사용)
    func deleteGroupStickers(groupId: String) -> Observable<Void> {
        return fetchList(query: .byGroup(groupId))
            .flatMap { [weak self] stickers -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(StickerError.fetchFailed("StickerManager 인스턴스가 없습니다"))
                }
                
                let deleteObservables = stickers.map { sticker in
                    self.delete(id: sticker.documentID)
                }
                return Observable.zip(deleteObservables).map { _ in () }
            }
    }
    
    /// 미션 완료 시 자동 스티커 생성 (핀번호 자동 계산)
    func createStickerFromMission(
        userId: String,
        groupId: String,
        missionTitle: String,
        maxStickers: Int,
        stickerType: String,
        missionId: String,
        assignedBy: String
    ) -> Observable<Void> {
        return fetchStickerCount(userId: userId)
            .flatMap { [weak self] currentCount -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(StickerError.fetchFailed("StickerManager 인스턴스가 없습니다"))
                }
                
                let now = Date()
                let calendar = Calendar.current
                let month = String(format: "%04d-%02d",
                                   calendar.component(.year, from: now),
                                   calendar.component(.month, from: now))
                
                // 핀번호 계산: 1~30개 = 핀1, 31~60개 = 핀2, ...
                let pinNumber = (currentCount / 30) + 1
                
                let sticker = StickerFirestore(
                    stickerId: UUID().uuidString,
                    userId: userId,
                    groupId: groupId,
                    month: month,
                    type: stickerType,
                    pinNumber: pinNumber,
                    createdAt: Timestamp(date: now),
                    missionId: missionId,
                    maxStickers: maxStickers,
                    assignedBy: assignedBy
                )
                
                return self.addSticker(sticker)
            }
    }
}
