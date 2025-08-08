//
//  MyMissionUseCase.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation
import RxSwift

protocol MyMissionUseCaseProtocol {
    func fetchMissions() -> Observable<[Mission]>
    func fetchAssignedMissions() -> Observable<[Mission]>
    func updateMissionStatus(for mission: Mission, to status: MissionStatus) -> Observable<Mission>
    func createSticker(mission: Mission) -> Observable<Void>
    func deleteSticker(missionID: String) -> Observable<Void>
}
