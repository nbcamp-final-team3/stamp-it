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
import FirebaseAuth // Added for Auth.auth()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Firebase 설정
        FirebaseApp.configure()
        
        // FCM 델리게이트 설정
        Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = true

        // UNUserNotificationCenter 델리게이트 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 알림 권한 요청
        requestNotificationPermission()
        
        // Firestore 네트워크 설정 개선
        configureFirestore()
        
        // Google Sign-In 설정
        configureGoogleSignIn()
        
        return true
    }
    
    // 알림 권한 요청
    private func requestNotificationPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            print("🔔 알림 권한: \(granted ? "허용됨" : "거부됨")")
            
            if let error = error {
                print("❌ 알림 권한 요청 에러: \(error)")
                return
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("📱 APNS 등록 요청됨")
                }
            }
        }
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

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // APNS 토큰 등록 성공
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ APNS Token 등록 성공")
        
        // ⭐ 중요: FCM에 APNS 토큰 설정
        Messaging.messaging().apnsToken = deviceToken
        
        // FCM 토큰은 MessagingDelegate에서 자동으로 처리됨
        // 별도로 저장하지 않음 (중복 방지)
    }
    
    // APNS 토큰 등록 실패
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ APNS 등록 실패: \(error)")
    }
    
    // 포그라운드에서 알림 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📱 포그라운드 알림 수신됨")
        completionHandler([.banner, .badge, .sound])
    }
    
    // 알림 탭했을 때 처리
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        print("👆 알림 탭됨: \(response.notification.request.content.userInfo)")
        
        // 딥링크 처리
        let userInfo = response.notification.request.content.userInfo
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let delegate = scene.delegate as? SceneDelegate {
            if let linkStr = (userInfo["deeplink"] as? String) ?? (userInfo["url"] as? String),
               let url = URL(string: linkStr) {
                // SceneDelegate로 포워딩 -> 알림 상태 조건 검사
                delegate.enqueueDeepLink(url)
            }
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    
    // FCM 토큰 갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken, !token.isEmpty else { return }
        
        print("🔥 FCM Token 갱신됨: \(token)")
        
        // 임시 캐시 (선택)
        UserDefaults.standard.set(token, forKey: "FCMToken")
        
        // 핵심: NotificationCenter 이벤트 브로드캐스트
        NotificationCenter.default.post(
            name: .fcmTokenDidRefresh,
            object: nil,
            userInfo: ["token": token]
        )
    }
}

// Notification 이름 확장
extension Notification.Name {
    static let fcmTokenDidRefresh = Notification.Name("FCMToken")
    static let mainUITabReady = Notification.Name("mainUITabReady")
}
