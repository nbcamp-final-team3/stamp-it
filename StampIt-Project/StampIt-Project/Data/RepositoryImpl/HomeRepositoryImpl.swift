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
    private let membershipManager: any MembershipManagerProtocol
    private let stickerManager: any StickerManagerProtocol
    private let missionManager: any MissionManagerProtocol

    init(
        membershipManager: any MembershipManagerProtocol,
        stickerManager: any StickerManagerProtocol,
        missionManager: any MissionManagerProtocol
    ) {
        self.membershipManager = membershipManager
        self.stickerManager = stickerManager
        self.missionManager = missionManager
    }

    func fetchGroupMembers(ofGroup groupID: String) -> Observable<[Member]> {
        let thisMonth = Date().toYearMonthString()
        return Observable.combineLatest(
            membershipManager.fetchMembers(groupId: groupID)
                .map { $0.map { $0.toDomainModel() } },
            stickerManager.fetchGroupStickers(groupId: groupID, month: thisMonth)
                .map { $0.map { $0.toDomainModel() } }
        )
        .map { members, stickers in
            let stickerMap = Dictionary(grouping: stickers) { $0.userID }
            return members.map { member in
                let count = stickerMap[member.userID]?.count ?? 0
                return Member(
                    userID: member.userID,
                    nickname: member.nickname,
                    profileImage: member.profileImage,
                    monthSticker: count,
                    joinedAt: member.joinedAt,
                    isLeader: member.isLeader
                )
            }
        }
    }

    func fetchStickers(ofGroup groupID: String, month: String) -> Observable<[Sticker]> {
        stickerManager.fetchGroupStickers(groupId: groupID, month: month)
            .map { $0.map { $0.toDomainModel() } }
    }

    func fetchMissions(
        to assigneeID: String?,
        by assignerID: String?,
        ofGroup groupID: String
    ) -> Observable<[Mission]> {
        missionManager.fetchMissions(to: assigneeID, by: assignerID, ofGroup: groupID)
            .map { $0.map { $0.toDomainModel() } }
    }

    func updateMissionStatus(for mission: Mission, ofGroup groupID: String, to status: MissionStatus) -> Observable<Mission> {
        let updated = MissionFirestore(
            missionId: mission.missionID,
            groupId: groupID,
            title: mission.title,
            assignedBy: mission.assignedBy,
            assignedTo: mission.assignedTo,
            createDate: Timestamp(date: mission.createDate),
            dueDate: Timestamp(date: mission.dueDate),
            category: mission.category.rawValue,
            status: status.rawValue,
            // TODO: 커스텀 타입 추가 시 도메인 모델 변경
            missionType: MissionFirestore.MissionType.app.rawValue,
        )

        return missionManager.updateMission(groupId: groupID, mission: updated)
            .map { $0.toDomainModel() }
    }

    func createSticker(
        userId: String,
        groupId: String,
        missionTitle: String,
        maxSticker: Int,
        stickerType: String,
        missionId: String,
        assignedBy: String
    ) -> Observable<Void> {
        stickerManager.createStickerFromMission(
            userId: userId,
            groupId: groupId,
            missionTitle: missionTitle,
            maxStickers: maxSticker,
            stickerType: stickerType,
            missionId: missionId,
            assignedBy: assignedBy
        )
    }

    func deleteSticker(missionID: String) -> Observable<Void> {
        stickerManager.deleteSticker(missionId: missionID)
    }
}
