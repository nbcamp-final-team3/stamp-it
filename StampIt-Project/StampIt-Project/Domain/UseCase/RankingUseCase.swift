//
//  HomeUseCase.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation
import RxSwift

protocol RankingUseCaseProtocol {
    func fetchCurrentUser() -> Observable<User?>
    func fetchRanking(ofGroup groupID: String) -> Observable<[Member]>
}
