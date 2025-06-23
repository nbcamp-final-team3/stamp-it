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

final class StickerManager: StickerManagerProtocol {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    private var stickersCollection: CollectionReference {
        return db.collection("stickers")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - Sticker Operations
    
    /// 특정 사용자의 월별 스티커 조회
    func fetchStickers(userId: String, month: String) -> Observable<[StickerFirestore]> {
        return Observable.create { observer in
            let listener = self.stickersCollection
                .whereField("userId", isEqualTo: userId)
                .whereField("month", isEqualTo: month)
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let stickers = try documents.compactMap { document -> StickerFirestore? in
                            return try document.data(as: StickerFirestore.self)
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
    
    /// 특정 사용자의 핀번호별 스티커 조회
    func fetchStickersByPin(userId: String, pinNumber: Int) -> Observable<[StickerFirestore]> {
        return Observable.create { observer in
            let listener = self.stickersCollection
                .whereField("userId", isEqualTo: userId)
                .whereField("pinNumber", isEqualTo: pinNumber)
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let stickers = try documents.compactMap { document -> StickerFirestore? in
                            return try document.data(as: StickerFirestore.self)
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
    
    /// 특정 사용자의 모든 스티커 조회
    func fetchAllUserStickers(userId: String) -> Observable<[StickerFirestore]> {
        return Observable.create { observer in
            let listener = self.stickersCollection
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let stickers = try documents.compactMap { document -> StickerFirestore? in
                            return try document.data(as: StickerFirestore.self)
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
    
    /// 특정 그룹의 모든 스티커 조회
    func fetchGroupStickers(groupId: String, month: String) -> Observable<[StickerFirestore]> {
        return Observable.create { observer in
            let listener = self.stickersCollection
                .whereField("groupId", isEqualTo: groupId)
                .whereField("month", isEqualTo: month)
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let stickers = try documents.compactMap { document -> StickerFirestore? in
                            return try document.data(as: StickerFirestore.self)
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
    
    /// 새 스티커 추가
    func addSticker(_ sticker: StickerFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.stickersCollection.document(sticker.documentID)
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
    
    /// 스티커 정보 업데이트
    func updateSticker(_ sticker: StickerFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.stickersCollection.document(sticker.documentID)
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
    
    // addSnapshotListener를 추가하되 최적화하기(새 페이지 생성 감지)
    func observeStickerCount(userId: String) -> Observable<Int> {
        return Observable.create { observer in
            let listener = self.stickersCollection
                .whereField("userId", isEqualTo: userId)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    let count = querySnapshot?.documents.count ?? 0
                    observer.onNext(count)
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
        .distinctUntilChanged() // 같은 값이면 방출하지 않음
        .debounce(.milliseconds(300), scheduler: MainScheduler.instance) // 연속 변경 방지
    }

    
    /// 특정 사용자의 현재 스티커 개수 조회
    func fetchStickerCount(userId: String) -> Observable<Int> {
        return Observable.create { observer in
            self.stickersCollection
                .whereField("userId", isEqualTo: userId)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    let count = querySnapshot?.documents.count ?? 0
                    observer.onNext(count)
                    observer.onCompleted()
                }
            
            return Disposables.create()
        }
    }
    
    /// 미션별 스티커 조회
    func fetchStickersByMission(missionId: String) -> Observable<[StickerFirestore]> {
        return Observable.create { observer in
            let listener = self.stickersCollection
                .whereField("missionId", isEqualTo: missionId)
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let stickers = try documents.compactMap { document -> StickerFirestore? in
                            return try document.data(as: StickerFirestore.self)
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
    
    /// 미션 완료 시 자동 스티커 생성
    func createStickerFromMission(
        userId: String,
        groupId: String,
        missionId: String,
        stickerType: String,
        assignedBy: String
    ) -> Observable<Void> {
        return fetchStickerCount(userId: userId)
            .flatMap { [weak self] currentCount -> Observable<Void> in
                guard let self = self else {
                    return Observable.error(StickerError.unknownError)
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
                    maxStickers: 30, // TODO: 향후 스티커판에 스티커 개수가 변동된다면 필요, 아니라면 삭제해도 될 것 같음
                    assignedBy: assignedBy
                )
                
                return self.addSticker(sticker)
            }
    }
    
    /// 특정 그룹에서 사용자 스티커 삭제 (그룹 탈퇴용)
    func deleteUserStickers(userId: String, groupId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.stickersCollection
                .whereField("userId", isEqualTo: userId)
                .whereField("groupId", isEqualTo: groupId)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.deleteFailed(error.localizedDescription))
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
                            observer.onError(StickerError.deleteFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                }
            return Disposables.create()
        }
    }
    
    /// 특정 사용자의 모든 스티커 삭제 (유저 탈퇴 시 사용)
    func deleteUserStickers(userId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.stickersCollection
                .whereField("userId", isEqualTo: userId)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.deleteFailed(error.localizedDescription))
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
                            observer.onError(StickerError.deleteFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
                }
            return Disposables.create()
        }
    }
    
    /// 특정 그룹의 모든 스티커 삭제
    func deleteGroupStickers(groupId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.stickersCollection
                .whereField("groupId", isEqualTo: groupId)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(StickerError.deleteFailed(error.localizedDescription))
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
                            observer.onError(StickerError.deleteFailed(error.localizedDescription))
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
