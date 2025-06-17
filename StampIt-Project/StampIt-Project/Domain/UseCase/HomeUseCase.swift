//
//  HomeUseCase.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation
import RxSwift

protocol HomeUseCaseProtocol {
    func fetchCurrentUser() -> Observable<User?>
    func fetchRanking(ofGroup groupID: String) -> Observable<[Member]>
    func fetchReceivedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]>
    func fetchSendedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]>
    func updateMissionStatus(for mission: Mission, ofGroup groupID: String, to status: MissionStatus) -> Observable<Void>
}
