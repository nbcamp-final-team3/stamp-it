//
//  MyMissionUseCase.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import Foundation
import RxSwift

protocol MyMissionUseCaseProtocol {
    func fetchReceivedMissions(ofUser userID: String, fromGroup groupID: String) -> Observable<[Mission]>
    func updateMissionStatus(for mission: Mission, ofGroup groupID: String, to status: MissionStatus) -> Observable<Mission>
    func createSticker(
        userId: String,
        groupId: String,
        missionTitle: String,
        maxSticker: Int,
        stickerType: String,
        assignedBy: String,
    ) -> Observable<Void>
}
