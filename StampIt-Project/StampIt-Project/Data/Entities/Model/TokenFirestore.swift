//
//  TokenFirestore.swift
//  StampIt-Project
//
//  Created by 윤주형 on 8/23/25.
//

import Foundation
import FirebaseFirestore

struct TokenFirestore: Codable {
    let userId: String
    let fcmToken: String
    let updatedAt: Timestamp
    
    init(userId: String, fcmToken: String) {
        self.userId = userId
        self.fcmToken = fcmToken
        self.updatedAt = Timestamp()
    }
}

