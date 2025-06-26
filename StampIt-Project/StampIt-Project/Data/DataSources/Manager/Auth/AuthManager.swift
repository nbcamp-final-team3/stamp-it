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
    
    // 유저탈퇴
    func revokeGoogleAccess() -> Observable<Void>
    func revokeAppleAccess() -> Observable<Void>
    func deleteAccountWithSocialRevoke() -> Observable<Void>
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
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
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
    
    // MARK: - Apple Sign-In Helper Methods
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

// TODO: 아래 애플 로그인의 경우 확인을 위해 print문을 많이 출력시켜둠, 다음 업데이트 전에 print문 삭제 필요
// MARK: - Apple Sign-In Delegates
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
            
            print("🍎 [Apple Login] 인증 성공 - 토큰 처리 시작")
            
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                
                print("🍎 [Apple Login] Apple ID Credential 획득")
                print("   - User ID: \(appleIDCredential.user)")
                print("   - Email: \(appleIDCredential.email ?? "없음")")
                print("   - Full Name: \(appleIDCredential.fullName?.description ?? "없음")")
                
                // 1. 필수 데이터 검증
                guard let nonce = currentNonce else {
                    print("❌ [Apple Login] Nonce가 없음")
                    appleSignInObserver?(.failure(AuthError.appleSignInFailed))
                    return
                }
                print("✅ [Apple Login] Nonce 검증 완료")
                
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("❌ [Apple Login] Identity Token이 없음")
                    appleSignInObserver?(.failure(AuthError.tokenRetrievalFailed))
                    return
                }
                print("✅ [Apple Login] Identity Token 획득")
                
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("❌ [Apple Login] Token String 변환 실패")
                    appleSignInObserver?(.failure(AuthError.tokenRetrievalFailed))
                    return
                }
                print("✅ [Apple Login] Token String 변환 완료")
                print("   - Token 길이: \(idTokenString.count)")
                
                // 2. Firebase 인증 자격 증명 생성
                print("🔥 [Firebase] Apple Credential 생성 중...")
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName
                )
                print("✅ [Firebase] Apple Credential 생성 완료")
                
                // 3. Firebase 로그인 수행
                print("🔥 [Firebase] Apple 로그인 시도 중...")
                Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                    if let error = error {
                        print("❌ [Firebase] Apple 로그인 실패: \(error.localizedDescription)")
                        print("   - Error Code: \((error as NSError).code)")
                        print("   - Error Domain: \((error as NSError).domain)")
                        self?.appleSignInObserver?(.failure(AuthError.firebaseSignInFailed))
                        return
                    }
                    
                    guard let authResult = authResult else {
                        print("❌ [Firebase] AuthResult가 없음")
                        self?.appleSignInObserver?(.failure(AuthError.unknownError))
                        return
                    }
                    
                    print("✅ [Firebase] Apple 로그인 성공!")
                    print("   - User ID: \(authResult.user.uid)")
                    print("   - Email: \(authResult.user.email ?? "없음")")
                    print("   - Display Name: \(authResult.user.displayName ?? "없음")")
                    print("   - Is New User: \(authResult.additionalUserInfo?.isNewUser ?? false)")
                    
                    self?.appleSignInObserver?(.success(authResult))
                    
                    // 정리
                    self?.appleSignInObserver = nil
                    self?.currentNonce = nil
                }
            } else {
                print("❌ [Apple Login] Apple ID Credential 타입 불일치")
                appleSignInObserver?(.failure(AuthError.appleSignInFailed))
            }
        }
    
    
    /// Apple Sign-In 인증 실패 시 호출되는 델리게이트 메서드
     func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
         
         print("❌ [Apple Login] 인증 실패: \(error.localizedDescription)")
         
         if let authError = error as? ASAuthorizationError {
             print("   - Error Code: \(authError.code.rawValue)")
             print("   - Error Description: \(authError.localizedDescription)")
             
             switch authError.code {
             case .canceled:
                 print("   - 사용자가 취소함")
                 appleSignInObserver?(.failure(AuthError.appleSignInCanceled))
             case .failed:
                 print("   - 인증 실패")
                 appleSignInObserver?(.failure(AuthError.appleSignInFailed))
             case .invalidResponse:
                 print("   - 잘못된 응답")
                 appleSignInObserver?(.failure(AuthError.appleSignInFailed))
             case .notHandled:
                 print("   - 처리되지 않음")
                 appleSignInObserver?(.failure(AuthError.appleSignInFailed))
             case .unknown:
                 print("   - 알 수 없는 오류")
                 appleSignInObserver?(.failure(AuthError.appleSignInFailed))
             default:
                 print("   - 새로운 오류 타입")
                 appleSignInObserver?(.failure(AuthError.appleSignInFailed))
             }
         } else {
             print("   - 일반 오류: \((error as NSError).code)")
             appleSignInObserver?(.failure(AuthError.appleSignInFailed))
         }
         
         // 정리
         appleSignInObserver = nil
         currentNonce = nil
     }
}

extension AuthManager {
    
    // MARK: - Google 액세스 토큰 취소
    func revokeGoogleAccess() -> Observable<Void> {
        return Observable.create { observer in
            guard GIDSignIn.sharedInstance.currentUser != nil else {
                // Google 로그인이 아닌 경우 성공 처리
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }
            
            GIDSignIn.sharedInstance.disconnect { error in
                if error != nil {
                    // 에러가 있어도 계속 진행 (Firebase 계정 삭제는 수행)
                    observer.onNext(())
                    observer.onCompleted()
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Apple 계정 연결 해제 (iOS 13.0+)
    func revokeAppleAccess() -> Observable<Void> {
        return Observable.create { observer in
            // Apple의 경우 직접적인 토큰 취소 API가 제한적
            // Firebase 계정 삭제만으로도 충분함
            observer.onNext(())
            observer.onCompleted()
            return Disposables.create()
        }
    }
    
    // MARK: - 소셜 로그인 취소 + Firebase 계정 삭제
    func deleteAccountWithSocialRevoke() -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self,
                  let currentUser = Auth.auth().currentUser else {
                observer.onError(AuthError.userNotFound)
                return Disposables.create()
            }
            
            // 1. 소셜 로그인 제공자 확인
            let providerId = currentUser.providerData.first?.providerID
            
            let revokeObservable: Observable<Void>
            switch providerId {
            case "google.com":
                revokeObservable = self.revokeGoogleAccess()
            case "apple.com":
                revokeObservable = self.revokeAppleAccess()
            default:
                revokeObservable = Observable.just(()) // 기타 제공자
            }
            
            // 2. 소셜 로그인 취소 → Firebase 계정 삭제
            revokeObservable
                .flatMap { _ -> Observable<Void> in
                    return self.deleteAccount()
                }
                .subscribe(
                    onNext: {
                        observer.onNext(())
                        observer.onCompleted()
                    },
                    onError: { error in
                        observer.onError(error)
                    }
                )
                .disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
}
