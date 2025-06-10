//
//  AuthRepository.swift
//  StampIt-Project
//
//  Created by iOS study on 6/10/25.
//

import Foundation
import RxSwift
import Firebase
import FirebaseFirestore

protocol AuthRepositoryProtocol {
    func signInWithGoogle() -> Observable<LoginResult>
    func signInWithApple() -> Observable<LoginResult>
    func signOut() -> Observable<Void>
    func deleteAccount() -> Observable<Void>
    func getCurrentUser() -> Observable<User?>
    func observeAuthState() -> Observable<User?>
    func checkLaunchState() -> Observable<LaunchResult>
}
