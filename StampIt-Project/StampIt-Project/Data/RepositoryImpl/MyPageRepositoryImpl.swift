//
//  MyPageRepositoryImpl.swift
//  StampIt-Project
//
//  Created by kingj on 6/12/25.
//

import Foundation
import RxSwift

final class MyPageRepositoryImpl: MyPageRepository {
    
    private let stickerManager: any StickerManagerProtocol
    private let userManager: any UserManagerProtocol
    
    init(
        stickerManager: any StickerManagerProtocol,
        userManager: any UserManagerProtocol
    ) {
        self.stickerManager = stickerManager
        self.userManager = userManager
    }
    
    func fetchStickersByPin(userId: String, pinNumber: Int) -> Observable<[Sticker]> {
        return stickerManager.fetchStickersByPin(userId: userId, pinNumber: pinNumber)
            .map { stickerFirestores in
                stickerFirestores.map { $0.toDomainModel() }
            }
    }
    
    func observeStickerCount(userId: String) -> Observable<Int> {    return stickerManager.observeStickerCount(userId: userId)
    }
    
    func fetchUserOnce(userId: String) -> Observable<User?> {
        userManager.fetchUserOnce(userId: userId)
            .map { $0.toDomainModel() }
    }
}
