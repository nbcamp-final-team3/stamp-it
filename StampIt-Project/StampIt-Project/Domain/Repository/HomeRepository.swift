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
    func fetchMissions(
        to assigneeID: String?,
        by assignerID: String?,
        ofGroup groupID: String
    ) -> Observable<[Mission]>
    func updateMissionStatus(for missionID: String, to status: MissionStatus)
}
