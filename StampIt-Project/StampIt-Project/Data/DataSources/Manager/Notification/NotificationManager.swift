//
//  NotificationService.swift
//  StampIt-Project
//
//  Created by 윤주형 on 12/19/25.
//

import Foundation
import RxSwift
import FirebaseFunctions

protocol NotificationServiceProtocol {
    // 특정 사용자에게 알림 전송
    func sendNotificationToUser(
        userId: String,
        title: String,
        body: String,
        data: [String: String]
    ) -> Observable<Void>
    
    // 그룹 멤버들에게 알림 전송
    func sendNotificationToGroup(
        groupId: String,
        title: String,
        body: String,
        data: [String: String]
    ) -> Observable<Void>
}

final class NotificationService: NotificationServiceProtocol {
    
    private let functions = Functions.functions()
    private let fcmManager: FCMManagerProtocol
    private let disposeBag = DisposeBag()
    
    init(fcmManager: FCMManagerProtocol) {
        self.fcmManager = fcmManager
    }
    
    func sendNotificationToUser(
        userId: String,
        title: String,
        body: String,
        data: [String: String]
    ) -> Observable<Void> {
        return Observable.create { observer in
            let callable = self.functions.httpsCallable("sendUserNotification")
            
            let payload: [String: Any] = [
                "recipientUserId": userId,
                "title": title,
                "body": body,
                "data": data
            ]
            
            callable.call(payload) { result, error in
                if let error = error {
                    observer.onError(RepositoryError.unknownError)
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    func sendNotificationToGroup(
        groupId: String,
        title: String,
        body: String,
        data: [String: String]
    ) -> Observable<Void> {
        return Observable.create { observer in
            let callable = self.functions.httpsCallable("sendGroupNotification")
            
            let payload: [String: Any] = [
                "groupId": groupId,
                "title": title,
                "body": body,
                "data": data
            ]
            
            callable.call(payload) { result, error in
                if let error = error {
                    observer.onError(RepositoryError.unknownError)
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
} 