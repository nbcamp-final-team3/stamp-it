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
            let assigner = member[mission.assignedBy]?.nickname ?? mission.assignedBy
            let homeMission = HomeMyMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assigner: assigner,
                isNew: isNew(createDate: mission.createDate),
                isOverdue: formatOverdueAndDays(from: mission.dueDate).isOverdue,
                status: mission.status
            )
            return homeMission
        }
    }

    /// [Mission]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
    func map(memberMission missions: [Mission], member: [String : Member]) -> [HomeMemberMission] {
        missions.map { mission in
            let assignee = member[mission.assignedTo]?.nickname ?? ""
            let (isOverdue, daysLeft) = formatOverdueAndDays(from: mission.dueDate)
            let homeMission = HomeMemberMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assignee: assignee,
                status: mission.status,
                isOverdue: isOverdue,
                daysLeft: daysLeft
            )
            return homeMission
        }
    }
}

// MARK: - Helper Methods

extension MissionMapper {
    private func formatOverdueAndDays(from dueDate: Date) -> (isOverdue: Bool, daysLeft: String) {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let dueStart = cal.startOfDay(for: dueDate)

        let dayDiff = cal.dateComponents([.day], from: todayStart, to: dueStart).day ?? 0

        let isOverdue = dayDiff < 0
        let daysLeft = dayDiff == 0 ? "오늘" : "\(dayDiff)일 전"

        return (isOverdue, daysLeft)
    }

    private func isNew(createDate: Date) -> Bool {
        let today = Calendar.current.dateComponents([.day], from: Date())
        let created = Calendar.current.dateComponents([.day], from: createDate)
        return today.day == created.day
    }
}
