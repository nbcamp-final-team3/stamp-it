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
    
    func fetchStickersByPin(userId: String, pinNumber: Int) -> Observable<[StickerUI]> {
        mypageRepository.fetchStickersByPin(userId: userId, pinNumber: pinNumber).map { $0.map { $0.toPresentation() } }
    }
    
    func observeStickerCount(userId: String) -> Observable<Int> {
        mypageRepository.observeStickerCount(userId: userId)
    }
}
