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
    
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void> {
        mypageRepository.updateUserNickname(userId: userId, nickname: nickname, changedAt: changedAt)
    }
    
    func fetchStickers(userId: String) -> Observable<[Sticker]> {
        mypageRepository.fetchStickers(userId: userId)
    }
}
