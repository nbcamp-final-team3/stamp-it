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
    func fetchStampsByPage(userId: String, page: Int) -> Observable<[Stamp]>
    func observeStampCount(userId: String) -> Observable<Int>
}
