//
//  FCMToken.swift
//  StampIt-Project
//
//  Created by 윤주형 on 8/23/25.
//

import Foundation

struct FCMToken {
    let tokenId: String
    let userId: String
    let fcmToken: String
    
    init(
        tokenId: String,
        userId: String,
        fcmToken: String
    ) {
        self.tokenId = tokenId
        self.userId = userId
        self.fcmToken = fcmToken
    }
}
