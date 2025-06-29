//
//  AppDelegate.swift
//  StampIt-Project
//
//  Created by iOS study on 6/4/25.
//

import UIKit
import CoreData
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Firebase 설정
        FirebaseApp.configure()
        
        // Firestore 네트워크 설정 개선
        configureFirestore()
        
        // 푸시 알림 권한 요청
        application.registerForRemoteNotifications()

        // FCM 델리게이트 설정
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        // Google Sign-In 설정
        configureGoogleSignIn()
        
        return true
    }
    
    // MARK: - Firestore 네트워크 오류 처리
    private func configureFirestore() {
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        db.settings = settings

        db.enableNetwork { error in
            if let error = error {
                print("❌ Firestore 네트워크 활성화 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 네트워크 활성화 성공")
            }
        }
    }
    
    // MARK: - Google Sign-In 설정 (수정됨)
    private func configureGoogleSignIn() {
        // 1차: Info.plist에서 GIDClientID 읽기
        if let clientId = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
            return
        }
        
        // 2차: GoogleService-Info.plist에서 읽기
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ Google Client ID를 찾을 수 없습니다.")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }

    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("🔗 URL 처리 시도: \(url.absoluteString)")
        
        // Google Sign-In URL 처리
        if GIDSignIn.sharedInstance.handle(url) {
            print("✅ Google Sign-In URL 처리 성공")
            return true
        }
        
        print("❌ URL 처리 실패")
        return false
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "StampIt_Project")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("FCM 토큰: \(fcmToken)")
        UserDefaults.standard.set(fcmToken, forKey: "FCMToken")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // 앱이 실행 중일 때 알림 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // 알림 탭했을 때
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // 미션 데이터가 있으면 처리
        if let missionData = userInfo["mission"] as? [String: Any] {
            let mission = Mission(
                missionID: missionData["missionID"] as? String ?? UUID().uuidString,
                title: missionData["title"] as? String ?? "새 미션",
                assignedTo: "me",
                assignedBy: missionData["assignedBy"] as? String ?? "누군가",
                createDate: Date(),
                dueDate: Date(),
                status: .assigned,
                imageURL: "",
                category: .chore
            )
            
            NotificationCenter.default.post(name: .newMissionReceived, object: mission)
        }
        
        completionHandler()
    }
}

extension Notification.Name {
    static let newMissionReceived = Notification.Name("newMissionReceived")
}
