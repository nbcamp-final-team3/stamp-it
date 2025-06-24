//
//  AppMissionManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/23/25.
//

// TODO: 관리자용은 내가 미션 일괄로 넣고 삭제하고 싶을때 사용하기 위해 구현

import Foundation
import FirebaseFirestore
import Firebase
import RxSwift

final class AppMissionManager: AppMissionManagerProtocol {
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    
    // MARK: - Collection Reference
    var appMissionsCollection: CollectionReference {
        return db.collection("appMissions")
    }
    
    // MARK: - Init
    init() {}
    
    // MARK: - AppMission Operations
    
    /// 앱 미션 목록 실시간 조회
    func fetchAppMissions() -> Observable<[AppMissionFirestore]> {
        return Observable.create { observer in
            let listener = self.appMissionsCollection
                .order(by: "category", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(AppMissionError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let appMissions = try documents.compactMap { document -> AppMissionFirestore? in
                            return try document.data(as: AppMissionFirestore.self)
                        }
                        observer.onNext(appMissions)
                    } catch {
                        observer.onError(AppMissionError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    /// 앱 미션 목록 일회성 조회 (캐싱용)
    func fetchAppMissionsOnce() -> Observable<[AppMissionFirestore]> {
        return Observable.create { observer in
            self.appMissionsCollection
                .order(by: "category", descending: false)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        observer.onError(AppMissionError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let appMissions = try documents.compactMap { document -> AppMissionFirestore? in
                            return try document.data(as: AppMissionFirestore.self)
                        }
                        observer.onNext(appMissions)
                        observer.onCompleted()
                    } catch {
                        observer.onError(AppMissionError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// 특정 앱 미션 조회
    func fetchAppMission(missionId: String) -> Observable<AppMissionFirestore?> {
        return Observable.create { observer in
            self.appMissionsCollection.document(missionId)
                .getDocument { documentSnapshot, error in
                    if let error = error {
                        observer.onError(AppMissionError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        observer.onNext(nil)
                        observer.onCompleted()
                        return
                    }
                    
                    do {
                        let appMission = try document.data(as: AppMissionFirestore.self)
                        observer.onNext(appMission)
                        observer.onCompleted()
                    } catch {
                        observer.onError(AppMissionError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    /// 카테고리별 앱 미션 조회
    func fetchAppMissionsByCategory(category: String) -> Observable<[AppMissionFirestore]> {
        return Observable.create { observer in
            let listener = self.appMissionsCollection
                .whereField("category", isEqualTo: category)
                .order(by: "title", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        observer.onError(AppMissionError.fetchFailed(error.localizedDescription))
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        observer.onNext([])
                        return
                    }
                    
                    do {
                        let appMissions = try documents.compactMap { document -> AppMissionFirestore? in
                            return try document.data(as: AppMissionFirestore.self)
                        }
                        observer.onNext(appMissions)
                    } catch {
                        observer.onError(AppMissionError.decodingFailed(error.localizedDescription))
                    }
                }
            
            return Disposables.create {
                listener.remove()
            }
        }
    }
    
    /// 새 앱 미션 생성 (관리자용)
    func createAppMission(_ appMission: AppMissionFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.appMissionsCollection.document(appMission.documentID)
                    .setData(from: appMission) { error in
                        if let error = error {
                            observer.onError(AppMissionError.createFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(AppMissionError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 앱 미션 정보 업데이트 (관리자용)
    func updateAppMission(_ appMission: AppMissionFirestore) -> Observable<Void> {
        return Observable.create { observer in
            do {
                try self.appMissionsCollection.document(appMission.documentID)
                    .setData(from: appMission, merge: true) { error in
                        if let error = error {
                            observer.onError(AppMissionError.updateFailed(error.localizedDescription))
                        } else {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }
            } catch {
                observer.onError(AppMissionError.encodingFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    /// 앱 미션 삭제 (관리자용)
    func deleteAppMission(missionId: String) -> Observable<Void> {
        return Observable.create { observer in
            self.appMissionsCollection.document(missionId)
                .delete { error in
                    if let error = error {
                        observer.onError(AppMissionError.deleteFailed(error.localizedDescription))
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create()
        }
    }
}
