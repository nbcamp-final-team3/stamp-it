//
//  MyPageUseCase.swift
//  StampIt-Project
//
//  Created by kingj on 6/12/25.
//

import Foundation
import RxSwift

protocol MyPageUseCaseProtocol {
    func fetchUserOnce(userId: String) -> Observable<User?>
    func fetchUser() -> Observable<User?>
    func fetchStampsByPin(userId: String, pinNumber: Int) -> Observable<[StampBoardStamp]>
    func observeStampCount(userId: String) -> Observable<Int>
}
