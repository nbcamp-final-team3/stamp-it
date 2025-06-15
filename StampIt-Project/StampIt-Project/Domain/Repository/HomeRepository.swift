//
//  HomeRepository.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation
import RxSwift

protocol HomeRepositoryProtocol {
    func fetchGroupMembers(ofGroup groupID: String) -> Observable<[User]>
    func fetchRecievedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]>
    func fetchSendedMissions(ofUser userID: String) -> Observable<[Mission]>
    func updateMissionStatus(for missionID: String, to status: MissionStatus)
}
