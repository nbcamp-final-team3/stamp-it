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
    
    func fetchStickers(userId: String) -> Observable<[Sticker]> {
        firestoreManager.fetchStickers(userId: userId, month: "1")
            .map { stickers in
                stickers.map { $0.toDomainModel() }
            }
    }
}
