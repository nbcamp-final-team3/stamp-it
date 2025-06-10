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

// MARK: - AuthManager Protocol
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
final class AuthManager: NSObject, AuthManagerProtocol {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    override init() {
        super.init()
        configureGoogleSignIn()
    }
    
    // MARK: - Configuration
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
    func signInWithGoogle() -> Observable<AuthDataResult> {
        return Observable.create { observer in
            // ✅ iOS 15.0+ 대응: UIWindowScene 사용
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let presentingViewController = windowScene.windows.first?.rootViewController else {
                observer.onError(AuthError.presentingViewControllerNotFound)
                return Disposables.create()
            }
            
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error = error {
                    observer.onError(AuthError.googleSignInFailed(error.localizedDescription))
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
                    if let error = error {
                        observer.onError(AuthError.firebaseSignInFailed(error.localizedDescription))
                    } else if let authResult = authResult {
                        observer.onNext(authResult)
                        observer.onCompleted()
                    }
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Apple Sign-In (준비)
    func signInWithApple() -> Observable<AuthDataResult> {
        return Observable.create { observer in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
            
            // TODO: Apple Sign-In 완료 후 Firebase 연동
            observer.onError(AuthError.appleSignInNotImplemented)
            return Disposables.create()
        }
    }
    
    // MARK: - Sign Out
    func signOut() -> Observable<Void> {
        return Observable.create { observer in
            do {
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(AuthError.signOutFailed(error.localizedDescription))
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() -> Observable<Void> {
        return Observable.create { observer in
            guard let user = Auth.auth().currentUser else {
                observer.onError(AuthError.userNotFound)
                return Disposables.create()
            }
            
            user.delete { error in
                if let error = error {
                    observer.onError(AuthError.accountDeletionFailed(error.localizedDescription))
                } else {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - Current User
    func getCurrentUser() -> FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    // MARK: - Auth State Observer
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
}

// MARK: - Apple Sign-In Delegates (준비)
extension AuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // ✅ iOS 15.0+ 대응: UIWindowScene 사용
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        return ASPresentationAnchor()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        // TODO: Apple Sign-In 완료 처리
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("❌ Apple Sign-In Error: \(error.localizedDescription)")
    }
}
