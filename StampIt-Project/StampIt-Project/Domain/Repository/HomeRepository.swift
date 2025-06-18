//
//  HomeRepository.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation
import RxSwift

protocol HomeRepositoryProtocol {
    func fetchGroupMembers(ofGroup groupID: String) -> Observable<[Member]>

    func fetchStickers(ofGroup groupID: String, month: String) -> Observable<[Sticker]>

    func fetchMissions(
        to assigneeID: String?,
        by assignerID: String?,
        ofGroup groupID: String
    ) -> Observable<[Mission]>

    func updateMissionStatus(
        for mission: Mission,
        ofGroup groupID: String,
        to status: MissionStatus
    ) -> Observable<Mission>

    func createSticker(
        userId: String,
        groupId: String,
        missionTitle: String,
        assignedBy: String,
        stickerType: String
    ) -> Observable<Void>
}
