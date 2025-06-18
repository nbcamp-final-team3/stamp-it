//
//  MyPageRepositoryImpl.swift
//  StampIt-Project
//
//  Created by kingj on 6/12/25.
//

import Foundation
import RxSwift

final class MyPageRepositoryImpl:
    MyPageRepository {
    
    private var firestoreManager: FirestoreManagerProtocol
    
    init(firestoreManager: FirestoreManagerProtocol) {
        self.firestoreManager = firestoreManager
    }
    
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void> {
        firestoreManager.updateUserNickname(
            userId: userId,
            nickname: nickname,
            changedAt: changedAt
        )
    }
    
    func fetchStickersByPin(userId: String, pinNumber: Int) -> Observable<[Sticker]> {
        firestoreManager.fetchStickersByPin(userId: userId, pinNumber: pinNumber)
            .map { stickers in
                stickers.map { $0.toDomainModel() }
            }
    }
    
    func fetchStickerCount(userId: String) -> Observable<Int> {
        firestoreManager.fetchStickerCount(userId: userId)
    }
}
