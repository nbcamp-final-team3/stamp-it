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
        
        // 딥링크 URL 처리
        if url.scheme == "stamp-it" {
            print("🔗 딥링크 URL 감지: \(url.absoluteString)")
            
            // SceneDelegate로 딥링크 전달
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let delegate = scene.delegate as? SceneDelegate {
                delegate.handleDeepLink(by: url)
                return true
            }
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
        
        // FCM 토큰 요청 및 Firestore 저장
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ FCM 토큰 가져오기 실패: \(error)")
            } else if let token = token {
                print("🔥 FCM Token: \(token)")
                UserDefaults.standard.set(token, forKey: "FCMToken")
                // Firestore에도 저장 (재시도 로직 포함)
                self.attemptToSaveFCMToken(token: token, retryCount: 0)
            }
        }
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
            delegate.handleDeeplinkFromNotification(userInfo)
        }
        
        completionHandler()
    }

    func handleDeeplink(_ userInfo: [AnyHashable: Any]) {
        guard let linkStr = userInfo["deeplink"] as? String,
              let url     = URL(string: linkStr),
              let scene   = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let delegate = scene.delegate as? SceneDelegate
        else { return }
        delegate.handleDeepLink(by: url)
    }
    
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    
    // FCM 토큰 갱신 시 호출
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔥 FCM Token 갱신됨: \(fcmToken ?? "없음")")
        
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "FCMToken")
            
            // Firestore에도 저장 (재시도 로직 포함)
            attemptToSaveFCMToken(token: token, retryCount: 0)
            
            // NotificationCenter로 토큰 전달
            let dataDict: [String: String] = ["token": token]
            NotificationCenter.default.post(
                name: Notification.Name("FCMToken"),
                object: nil,
                userInfo: dataDict
            )
        }
    }
    
         // FCM 토큰 저장 재시도
    private func attemptToSaveFCMToken(token: String, retryCount: Int) {
        let maxRetries = 5
        
        if let firebaseUID = Auth.auth().currentUser?.uid {
            print("✅ Firebase Auth UID 발견: \(firebaseUID)")
            uploadFCMTokenToFirestore(token)
            return
        }
        
        if retryCount < maxRetries {
            print("⏳ Firebase Auth 대기 중... \(retryCount + 1)/\(maxRetries) (2초 후 재시도)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.attemptToSaveFCMToken(token: token, retryCount: retryCount + 1)
            }
        } else {
            print("❌ 최대 재시도 횟수 초과. FCM 토큰 저장 실패")
            print("⚠️ Firebase Auth 상태를 확인해주세요")
        }
    }
    
    // Firestore에 FCM 토큰 업로드
    private func uploadFCMTokenToFirestore(_ token: String) {
        // Firebase Auth의 현재 사용자 UID 사용
        guard let firebaseUID = Auth.auth().currentUser?.uid else { 
            print("❌ Firebase Auth 사용자 UID를 찾을 수 없음")
            return 
        }
        
        print(" Firebase Auth UID로 FCM 토큰 저장 시작: \(firebaseUID)")
        
        let db = Firestore.firestore()
        db.collection("users").document(firebaseUID).setData([
            "fcmToken": token
        ], merge: true) { error in
            if let error = error {
                print("❌ FCM 토큰 Firestore 저장 실패: \(error)")
            } else {
                print("✅ FCM 토큰 Firestore 저장 성공: users/\(firebaseUID)")
            }
        }
    }
}
