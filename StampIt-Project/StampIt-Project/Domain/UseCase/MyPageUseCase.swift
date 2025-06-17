//
//  MyPageUseCase.swift
//  StampIt-Project
//
//  Created by kingj on 6/12/25.
//

import Foundation
import RxSwift

protocol MyPageUseCase {
    func fetchUser() -> Observable<User?>
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void>
    func fetchStickersByPin(userId: String, pinNumber: Int) -> Observable<[Sticker]>
    func fetchStickerCount(userId: String) -> Observable<Int>
}
