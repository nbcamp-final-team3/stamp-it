//
//  AppMissionDTO.swift
//  StampIt-Project
//
//  Created by iOS study on 6/5/25.
//

import Foundation
import FirebaseFirestore

struct AppMissionFirestore: Codable {
    let missionId: String           // 문서 ID
    let title: String
    let category: String
    let missionType: String
    
    var documentID: String {
        return missionId
    }
}
