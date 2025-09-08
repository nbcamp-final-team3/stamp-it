//
//  MyPageRepositoryImpl.swift
//  StampIt-Project
//
//  Created by kingj on 6/12/25.
//

import Foundation
import RxSwift

final class MyPageRepositoryImpl: MyPageRepository {
    
    private let stampManager: any StampManagerProtocol
    private let userManager: any UserManagerProtocol
    
    init(
        stampManager: any StampManagerProtocol,
        userManager: any UserManagerProtocol
    ) {
        self.stampManager = stampManager
        self.userManager = userManager
    }
    
    func fetchStampsByPin(userId: String, pinNumber: Int) -> Observable<[Stamp]> {
        return stampManager.fetchStampsByPin(userId: userId, pinNumber: pinNumber)
            .map { stampFirestores in
                stampFirestores.map { $0.toDomainModel() }
            }
    }
    
    func observeStampCount(userId: String) -> Observable<Int> {    return stampManager.observeStampCount(userId: userId)
    }
    
    func fetchUserOnce(userId: String) -> Observable<User?> {
        userManager.fetchUserOnce(userId: userId)
            .map { $0.toDomainModel() }
    }
}
