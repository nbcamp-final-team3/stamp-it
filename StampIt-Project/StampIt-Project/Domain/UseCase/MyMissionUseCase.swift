//
//  MyMissionUseCase.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation
import RxSwift

protocol MyMissionUseCaseProtocol {
    func fetchGroupMembers() -> Observable<[String: Member]>
    func fetchMissions() -> Observable<[Mission]>
    func fetchAssignedMissions() -> Observable<[Mission]>
    func updateMissionStatus(for mission: Mission, to status: MissionStatus) -> Observable<Mission>
    func createStamp(mission: Mission) -> Observable<Void>
    func deleteStamp(missionID: String) -> Observable<Void>
}
