//
//  MissionMapping.swift
//  StampIt-Project
//
//  Created by daeun on 6/24/25.
//

import Foundation

protocol MissionMapping {
    func map(myMissions: [Mission], member: [String: Member]) -> [HomeMyMission]
    func map(memberMission: [Mission], member: [String: Member]) -> [HomeMemberMission]
    func map(widgetMissions missions: [Mission], member: [String: Member]) -> [HomeMissionWidget]
}
