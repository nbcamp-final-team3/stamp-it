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
    private let stampManager: any StampManagerProtocol
    private let missionManager: any MissionManagerProtocol

    init(
        membershipManager: any MembershipManagerProtocol,
        stampManager: any StampManagerProtocol,
        missionManager: any MissionManagerProtocol
    ) {
        self.membershipManager = membershipManager
        self.stampManager = stampManager
        self.missionManager = missionManager
    }

    func fetchGroupMembers(ofGroup groupID: String) -> Observable<[Member]> {
        let thisMonth = Date().toYearMonthString()
        return Observable.combineLatest(
            membershipManager.fetchMembers(groupId: groupID)
                .map { $0.map { $0.toDomainModel() } },
            stampManager.fetchGroupStamps(groupId: groupID, month: thisMonth)
                .map { $0.map { $0.toDomainModel() } }
        )
        .map { members, stamps in
            let stampMap = Dictionary(grouping: stamps) { $0.userID }
            return members.map { member in
                let count = stampMap[member.userID]?.count ?? 0
                return Member(
                    userID: member.userID,
                    nickname: member.nickname,
                    profileImage: member.profileImage,
                    monthStamp: count,
                    joinedAt: member.joinedAt,
                    isLeader: member.isLeader
                )
            }
        }
    }

    func fetchStamps(ofGroup groupID: String, month: String) -> Observable<[Stamp]> {
        stampManager.fetchGroupStamps(groupId: groupID, month: month)
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

    func createStamp(
        userId: String,
        groupId: String,
        missionTitle: String,
        maxStamp: Int,
        stampType: String,
        missionId: String,
        assignedBy: String
    ) -> Observable<Void> {
        stampManager.createStampFromMission(
            userId: userId,
            groupId: groupId,
            missionTitle: missionTitle,
            maxStamps: maxStamp,
            stampType: stampType,
            missionId: missionId,
            assignedBy: assignedBy
        )
    }

    func deleteStamp(missionID: String) -> Observable<Void> {
        stampManager.deleteStamp(missionId: missionID)
    }
}
