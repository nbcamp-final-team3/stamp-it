//
//  MissionMapper.swift
//  StampIt-Project
//
//  Created by daeun on 6/24/25.
//

import Foundation

final class MissionMapper: MissionMapping {

    /// [Mission]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
    func map(myMissions missions: [Mission], member: [String : Member]) -> [HomeMyMission] {
        missions.map { mission in
            let assigner = member[mission.assignedBy]?.nickname ?? "탈퇴한 멤버"
            let homeMission = HomeMyMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assigner: assigner,
                isNew: mission.isNew,
                isOverdue: mission.isOverdue,
                isCancelableCompleted: mission.isCancelableCompleted,
                status: mission.status
            )
            return homeMission
        }
    }

    /// [Mission]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
    func map(memberMission missions: [Mission], member: [String : Member]) -> [HomeMemberMission] {
        missions.map { mission in
            let assignee = member[mission.assignedTo]?.nickname ?? "탈퇴한 멤버"
            let daysBefore = daysBefore(from: mission.createDate)
            let homeMission = HomeMemberMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assignee: assignee,
                status: mission.status,
                isOverdue: mission.isOverdue,
                daysBefore: daysBefore
            )
            return homeMission
        }
    }
}

// MARK: - Helper Methods

extension MissionMapper {
    /// 몇 일 전에 받은 미션인지 계산하여 0일 전이면 오늘로 표기
    private func daysBefore(from createDate: Date) -> String {
        let dayDiff = createDate.daysFromToday(absoluteValue: true)
        return dayDiff == 0 ? "오늘" : "\(dayDiff)일 전"
    }
}
