//
//  MyPageUseCaseImpl.swift
//  StampIt-Project
//
//  Created by kingj on 6/12/25.
//

import Foundation
import RxSwift

final class MyPageUseCaseImpl: MyPageUseCase {
    
    private let authRepository: AuthRepositoryProtocol
    private let mypageRepository: MyPageRepository
    
    init(
        authRepository: AuthRepositoryProtocol,
        mypageRepository: MyPageRepository
    ) {
        self.authRepository = authRepository
        self.mypageRepository = mypageRepository
    }
    
    func fetchUser() -> Observable<User?> {
        authRepository.getCurrentUser()
    }
    
    func fetchStickersByPin(userId: String, pinNumber: Int) -> Observable<[Sticker]> {
        mypageRepository.fetchStickersByPin(userId: userId, pinNumber: pinNumber)
    }
    
    func fetchStickerCount(userId: String) -> Observable<Int> {
        mypageRepository.fetchStickerCount(userId: userId)
    }
}
