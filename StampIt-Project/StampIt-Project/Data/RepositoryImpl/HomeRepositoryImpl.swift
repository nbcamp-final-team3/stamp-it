//
//  HomeRepositoryImpl.swift
//  StampIt-Project
//
//  Created by daeun on 6/13/25.
//

import Foundation
import RxSwift
import FirebaseFirestore

final class HomeRepository: HomeRepositoryProtocol {
    private let manager: FirestoreManagerProtocol

    init(manager: FirestoreManagerProtocol) {
        self.manager = manager
    }

    func fetchGroupMembers(ofGroup groupID: String) -> Observable<[Member]> {
        let thisMonth = Date().toYearMonthString()
        return Observable.zip(
            manager.fetchMembers(groupId: groupID)
                .map { $0.map { $0.toDomainModel() } },
            manager.fetchGroupStickers(groupId: groupID, month: thisMonth)
                .map { $0.map { $0.toDomainModel() } }
        )
        .map { members, stickers in
            let stickerMap = Dictionary(grouping: stickers) { $0.userID }
            return members.map { member in
                let count = stickerMap[member.userID]?.count ?? 0
                return Member(
                    userID: member.userID,
                    nickname: member.nickname,
                    profileImageURL: member.profileImageURL,
                    monthSticker: count,
                    joinedAt: member.joinedAt,
                    isLeader: member.isLeader
                )
            }
        }
    }

    func fetchStickers(ofGroup groupID: String, month: String) -> Observable<[Sticker]> {
        manager.fetchGroupStickers(groupId: groupID, month: month)
            .map { $0.map { $0.toDomainModel() } }
    }

    func fetchMissions(
        to assigneeID: String?,
        by assignerID: String?,
        ofGroup groupID: String
    ) -> Observable<[Mission]> {
        manager.fetchMissions(to: assigneeID, by: assignerID, ofGroup: groupID)
            .map { $0.map { $0.toDomainModel() } }
    }
    
    func updateMissionStatus(for mission: Mission, ofGroup groupID: String, to status: MissionStatus) -> Observable<Void> {
        let updated = MissionFirestore(
            missionId: mission.missionID,
            title: mission.title,
            assignedBy: mission.assignedBy,
            assignedTo: mission.assignedTo,
            createDate: Timestamp(date: mission.createDate),
            dueDate: Timestamp(date: mission.dueDate),
            category: mission.category.rawValue,
            status: status.rawValue,
            // TODO: 커스텀 타입 추가 시 도메인 모델 변경
            missionType: MissionFirestore.MissionType.app.rawValue,
            createdAt: Timestamp(date: mission.createDate)
        )

        return manager.updateMission(groupId: groupID, mission: updated)
    }
}
