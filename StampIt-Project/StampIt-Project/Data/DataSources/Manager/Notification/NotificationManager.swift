//
//  NotificationManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/27/25.
//

import UserNotifications
import AVFoundation

final class NotificationManager {
    static let shared = NotificationManager()
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한 허용됨")
            } else {
                print("알림 권한 거부됨")
            }
        }
    }
}
