//
//  NotificationManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/27/25.
//

import Foundation
import FirebaseMessaging
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var fcmToken: String = ""
    @Published var isNotificationEnabled: Bool = false
    
    private init() {
        getFCMToken()
        checkNotificationStatus()
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func getFCMToken() {
        if let token = UserDefaults.standard.string(forKey: "FCMToken") {
            self.fcmToken = token
        }
        
        Messaging.messaging().token { token, _ in
            if let token = token {
                DispatchQueue.main.async {
                    self.fcmToken = token
                }
            }
        }
    }
    
    func sendLocalNotification(title: String, body: String, userInfo: [String: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
