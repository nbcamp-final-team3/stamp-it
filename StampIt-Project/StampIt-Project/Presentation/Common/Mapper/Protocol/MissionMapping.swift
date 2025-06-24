//
//  MissionMapping.swift
//  StampIt-Project
//
//  Created by daeun on 6/24/25.
//

import Foundation

protocol MissionMapping {
    func map(myMissions: [Mission], member: [String: Member]) -> [HomeItem]
    func map(memberMission: [Mission], member: [String: Member]) -> [HomeItem]
}
