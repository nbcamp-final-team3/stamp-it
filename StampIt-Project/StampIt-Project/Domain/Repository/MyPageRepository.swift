//
//  MyPageRepository.swift
//  StampIt-Project
//
//  Created by kingj on 6/12/25.
//

import Foundation
import RxSwift

protocol MyPageRepository {
    func fetchUserOnce(userId: String) -> Observable<User?>
    func fetchStickersByPin(userId: String, pinNumber: Int) -> Observable<[Sticker]>
    func observeStickerCount(userId: String) -> Observable<Int>
}
