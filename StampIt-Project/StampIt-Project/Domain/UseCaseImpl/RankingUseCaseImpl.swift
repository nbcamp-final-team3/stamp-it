//
//  HomeUseCaseImpl.swift
//  StampIt-Project
//
//  Created by daeun on 6/13/25.
//

import Foundation
import RxSwift

final class RankingUseCase: RankingUseCaseProtocol {
    let authRepository: AuthRepositoryProtocol
    let homeRepository: HomeRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol, homeRepository: HomeRepositoryProtocol) {
        self.authRepository = authRepository
        self.homeRepository = homeRepository
    }

    func fetchCurrentUser() -> Observable<User?> {
        authRepository.getCurrentUser()
    }
	
    func fetchRanking(ofGroup groupID: String) -> Observable<[Member]> {
        homeRepository.fetchGroupMembers(ofGroup: groupID)
            .map { members in
                members.sorted { $0.monthStamp > $1.monthStamp }
            }
    }
}
