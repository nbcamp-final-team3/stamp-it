//
//  MyPageUseCaseImpl.swift
//  StampIt-Project
//
//  Created by kingj on 6/12/25.
//

import Foundation
import RxSwift

final class MyPageUseCaseImpl: MyPageUseCaseProtocol {
    
    private let authRepository: AuthRepositoryProtocol
    private let mypageRepository: MyPageRepository
    
    init(
        authRepository: AuthRepositoryProtocol,
        mypageRepository: MyPageRepository
    ) {
        self.authRepository = authRepository
        self.mypageRepository = mypageRepository
    }
    
    func fetchUserOnce(userId: String) -> Observable<User?> {
        mypageRepository.fetchUserOnce(userId: userId)
    }
    
    func fetchUser() -> Observable<User?> {
        authRepository.getCurrentUser()
    }
    
    func fetchStampsByPin(userId: String, pinNumber: Int) -> Observable<[StampBoardStamp]> {
        mypageRepository.fetchStampsByPin(userId: userId, pinNumber: pinNumber).map { $0.map { $0.toPresentation() } }
    }
    
    func observeStampCount(userId: String) -> Observable<Int> {
        mypageRepository.observeStampCount(userId: userId)
    }
}
