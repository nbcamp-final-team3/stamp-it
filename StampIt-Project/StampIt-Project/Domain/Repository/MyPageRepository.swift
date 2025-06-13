//
//  MyPageRepository.swift
//  StampIt-Project
//
//  Created by kingj on 6/12/25.
//

import Foundation
import RxSwift

protocol MyPageRepository {
    func updateUserNickname(userId: String, nickname: String, changedAt: Date) -> Observable<Void>
    func fetchStickers(userId: String) -> Observable<[Sticker]>
}
