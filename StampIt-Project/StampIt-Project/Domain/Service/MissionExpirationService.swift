//
//  MissionExpirationService.swift
//  StampIt-Project
//
//  Created by daeun on 6/24/25.
//

import Foundation

protocol MissionExpirationService {
    func handleExpiredMissions(_ missions: [Mission], groupID: String)
}
