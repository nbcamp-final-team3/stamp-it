//
//  AuthManager.swift
//  StampIt-Project
//
//  Created by iOS study on 6/10/25.
//

import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn
import RxSwift
import AuthenticationServices

// MARK: - AuthManagerProtocol
protocol AuthManagerProtocol {
    func configureGoogleSignIn()
    func signInWithGoogle() -> Observable<AuthDataResult>
    func signInWithApple() -> Observable<AuthDataResult>
    func signOut() -> Observable<Void>
    func deleteAccount() -> Observable<Void>
    func getCurrentUser() -> FirebaseAuth.User?
    func observeAuthState() -> Observable<FirebaseAuth.User?>
}

// MARK: - AuthManager Implementation
final class AuthManager: NSObject,AuthManagerProtocol {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var currentNonce: String?
    private var appleSignInObserver: ((Result<AuthDataResult, Error>) -> Void)?
    
    // MARK: - Init
    override init() {
        super.init()
        configureGoogleSignIn()
    }
    
    // MARK: - Configuration
    /// Google Sign-In 설정을 초기화하고 CLIENT_ID를 구성
    func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        print("✅ Google Sign-In configured successfully")
    }
    
    // MARK: - Google Sign-In
    /// Google 로그인을 수행하고 Firebase 인증 결과를 반환
    func signInWithGoogle() -> Observable<AuthDataResult> {
        return Observable.create { observer in
            // iOS 15.0+ 대응: UIWindowScene 사용
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let presentingViewController = windowScene.windows.first?.rootViewController else {
                observer.onError(AuthError.presentingViewControllerNotFound)
                return Disposables.create()
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if error != nil {
                    observer.onError(AuthError.googleSignInFailed)
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    observer.onError(AuthError.tokenRetrievalFailed)
                    return
                }
                
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if error != nil {
                        observer.onError(AuthError.firebaseSignInFailed)
                    } else if let authResult = authResult {
                        observer.onNext(authResult)
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Apple Sign-In
    func signInWithApple() -> Observable<AuthDataResult> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(AuthError.unknownError)
                return Disposables.create()
            }
            
            // 1. Nonce 생성
            let nonce = self.randomNonceString()
            self.currentNonce = nonce
            
            // 2. Apple 요청 준비
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = nonce.sha256
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            
            // 3. 콜백 저장
            self.appleSignInObserver = { result in
                switch result {
                case .success(let authDataResult):
                    observer.onNext(authDataResult)
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            
            // 4. 요청 시작
            authorizationController.performRequests()
            
            return Disposables.create {
                self.appleSignInObserver = nil
            }
        }
    }
    
    // MARK: - Sign Out
    /// 현재 사용자를 로그아웃하고 Google Sign-In도 함께 로그아웃
    func signOut() -> Observable<Void> {
        return Observable.create { observer in
            do {
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(AuthError.signOutFailed)
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Delete Account
    /// 현재 사용자 계정을 완전히 삭제
    func deleteAccount() -> Observable<Void> {
        return Observable.create { observer in
            guard let user = Auth.auth().currentUser else {
                observer.onError(AuthError.userNotFound)
                return Disposables.create()
            }
            
            user.delete { error in
                if error != nil {
                    observer.onError(AuthError.accountDeletionFailed)
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - User State Methods
    /// 현재 Firebase 인증된 사용자를 반환
    func getCurrentUser() -> FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    /// Firebase 인증 상태 변화를 실시간으로 관찰
    func observeAuthState() -> Observable<FirebaseAuth.User?> {
        return Observable.create { observer in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                observer.onNext(user)
            }
            
            return Disposables.create {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
    
    // MARK: - Apple Sign-In Helper Methods (✅ 추가)
    /// 랜덤 Nonce 문자열 생성 (보안용)
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}

// MARK: - Apple Sign-In Delegates (준비, 구조 변경 될 수 있음)
extension AuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    /// Apple Sign-In 화면을 표시할 윈도우를 반환
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // iOS 15.0+ 대응: UIWindowScene 사용
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        return ASPresentationAnchor()
    }
    
    /// Apple Sign-In 인증 성공 시 호출되는 델리게이트 메서드
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            // 1. 필수 데이터 검증
            guard let nonce = currentNonce else {
                print("❌ Invalid state: A login callback was received, but no login request was sent.")
                appleSignInObserver?(.failure(AuthError.appleSignInFailed))
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("❌ Unable to fetch identity token")
                appleSignInObserver?(.failure(AuthError.tokenRetrievalFailed))
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("❌ Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                appleSignInObserver?(.failure(AuthError.tokenRetrievalFailed))
                return
            }
            
            // 2. Firebase 인증 자격 증명 생성 (✅ 수정된 부분)
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            // 3. Firebase 로그인 수행
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let error = error {
                    print("❌ Firebase Apple Sign-In Error: \(error.localizedDescription)")
                    self?.appleSignInObserver?(.failure(AuthError.firebaseSignInFailed))
                    return
                }
                
                guard let authResult = authResult else {
                    self?.appleSignInObserver?(.failure(AuthError.unknownError))
                    return
                }
                
                print("✅ Apple Sign-In 성공: \(authResult.user.uid)")
                self?.appleSignInObserver?(.success(authResult))
                
                // 정리
                self?.appleSignInObserver = nil
                self?.currentNonce = nil
            }
        }
    }
    
    /// Apple Sign-In 인증 실패 시 호출되는 델리게이트 메서드
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In Error: \(error.localizedDescription)")
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                appleSignInObserver?(.failure(AuthError.appleSignInCanceled))
            default:
                appleSignInObserver?(.failure(AuthError.appleSignInFailed))
            }
        } else {
            appleSignInObserver?(.failure(AuthError.appleSignInFailed))
        }
        
        // 정리
        appleSignInObserver = nil
        currentNonce = nil
    }
}
