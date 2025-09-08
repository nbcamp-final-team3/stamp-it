//
//  MyMissionUseCase.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation
import RxSwift

protocol MyMissionUseCaseProtocol {
    func fetchMissions(to userID: String?, ofGroup groupID: String) -> Observable<[Mission]>
    func fetchAssignedMissions(to userID: String?, ofGroup groupID: String) -> Observable<[Mission]>
    func updateMissionStatus(for mission: Mission, ofGroup groupID: String, to status: MissionStatus) -> Observable<Mission>
    func createStamp(user: User, mission: Mission) -> Observable<Void>
    func deleteStamp(missionID: String) -> Observable<Void>
}
