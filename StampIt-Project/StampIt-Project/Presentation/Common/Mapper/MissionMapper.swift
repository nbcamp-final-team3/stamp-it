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
                isNew: isNew(createDate: mission.createDate),
                isOverdue: isOverdue(from: mission.dueDate),
                status: mission.status
            )
            return homeMission
        }
    }

    /// [Mission]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
    func map(memberMission missions: [Mission], member: [String : Member]) -> [HomeMemberMission] {
        missions.map { mission in
            let assignee = member[mission.assignedTo]?.nickname ?? "탈퇴한 멤버"
            let isOverdue = isOverdue(from: mission.dueDate)
            let daysBefore = daysBefore(from: mission.createDate)
            let homeMission = HomeMemberMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assignee: assignee,
                status: mission.status,
                isOverdue: isOverdue,
                daysBefore: daysBefore
            )
            return homeMission
        }
    }
}

// MARK: - Helper Methods

extension MissionMapper {
    /// 만료 체크
    private func isOverdue(from dueDate: Date) -> Bool {
        let dayDiff = dueDate.daysFromToday()
        return dayDiff < 0
    }

    /// 몇 일 전에 받은 미션인지 계산하여 0일 전이면 오늘로 표기
    private func daysBefore(from createDate: Date) -> String {
        let dayDiff = createDate.daysFromToday(absoluteValue: true)
        return dayDiff == 0 ? "오늘" : "\(dayDiff)일 전"
    }

    private func isNew(createDate: Date) -> Bool {
        let today = Calendar.current.dateComponents([.day], from: Date())
        let created = Calendar.current.dateComponents([.day], from: createDate)
        return today.day == created.day
    }
}
