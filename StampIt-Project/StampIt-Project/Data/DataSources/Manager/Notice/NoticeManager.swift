//
//  NoticeManager.swift
//  StampIt-Project
//
//  Created by 윤주형 study on 7/11/25.
//

import Foundation
import FirebaseFirestore
import RxSwift

final class NoticeManager: NoticeManagerProtocol {
    private let db = Firestore.firestore()
    var noticeCollection: CollectionReference {
        db.collection("DataNoticeFirestore")
    }

    init() {}

    // MARK: - 알림 생성 (Firestore 저장 → FCM 푸시 트리거)
    /// Firestore에 알림 데이터를 저장  - 저장 후, 서버/클라우드 함수가 해당 userId로 FCM 푸시 알림을 전송함.
    func create(notice: NoticeFirestore) -> Observable<Void> {
        Observable.create { observer in
            do {
                try self.noticeCollection.document(notice.noticeId).setData(from: notice) { error in
                    if let error = error {
                        observer.onError(NoticeError.updateFailed(error.localizedDescription))
                    } else {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }
            } catch {
                observer.onError(NoticeError.decodingFailed(error.localizedDescription))
            }
            return Disposables.create()
        }
    }

    // MARK: - 실시간 알림 구독 (앱 내 알림 리스트)
    /// Firestore에서 내 userId 등 조건에 맞는 알림을 실시간 구독 - 앱이 켜져 있을 때 알림 리스트를 자동 갱신.
    func observeNotices(query: NoticeQuery) -> Observable<[NoticeFirestore]> {
        Observable.create { observer in
            var firestoreQuery: Query = self.noticeCollection
            
            if let userId = query.userId {
                firestoreQuery = firestoreQuery.whereField("userId", isEqualTo: userId)
            }
            if let isRead = query.isRead {
                firestoreQuery = firestoreQuery.whereField("isRead", isEqualTo: isRead)
            }
            if let orderBy = query.orderBy {
                switch orderBy {
                case .createdAtDesc:
                    firestoreQuery = firestoreQuery.order(by: "createdAt", descending: true)
                case .createdAtAsc:
                    firestoreQuery = firestoreQuery.order(by: "createdAt", descending: false)
                }
            }
            if let limit = query.limit {
                firestoreQuery = firestoreQuery.limit(to: limit)
            }
            
            let listener = firestoreQuery.addSnapshotListener { snapshot, error in
                if let error = error {
                    observer.onError(NoticeError.fetchFailed(error.localizedDescription))
                    return
                }
                guard let documents = snapshot?.documents else {
                    observer.onNext([])
                    return
                }
                do {
                    let notices = try documents.compactMap { try $0.data(as: NoticeFirestore.self) }
                    observer.onNext(notices)
                } catch {
                    observer.onError(NoticeError.decodingFailed(error.localizedDescription))
                }
            }
            return Disposables.create { listener.remove() }
        }
    }

    // MARK: - 알림 읽음 처리
    /// 알림cell 또는 푸시탭 시 호출 - 해당 알림의 isRead를 true로 업데이트.
    func markAsRead(id: String) -> Observable<Void> {
        Observable.create { observer in
            self.noticeCollection.document(id).updateData(["isRead": true]) { error in
                if let error = error {
                    observer.onError(NoticeError.updateFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    // MARK: - 알림 삭제
    /// 알림cell에서 삭제 시 호출 - Firestore에서 해당 알림 문서를 삭제.
    func delete(id: String) -> Observable<Void> {
        Observable.create { observer in
            self.noticeCollection.document(id).delete { error in
                if let error = error {
                    observer.onError(NoticeError.updateFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}
