//
//  LoginUseCase.swift
//  StampIt-Project
//
//  Created by iOS study on 6/11/25.
//

import RxSwift

// MARK: - LoginUseCase Protocol
protocol LoginUseCaseProtocol {
    // MARK: - Login
    func loginWithGoogle() -> Observable<LoginFlowResult>
    func loginWithApple() -> Observable<LoginFlowResult>
    
    // MARK: - Launch Check
    func checkLaunchState() -> Observable<LaunchFlowResult>
}
