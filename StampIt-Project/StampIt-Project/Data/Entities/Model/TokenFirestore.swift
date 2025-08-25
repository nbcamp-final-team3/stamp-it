//
//  TokenFirestore.swift
//  StampIt-Project
//
//  Created by 윤주형 on 8/23/25.
//

import Foundation
import FirebaseFirestore

struct TokenFirestore: Codable {
    let tokenId: String
    let userId: String
    let fcmToken: String
    
    var documentID: String { return tokenId }
}

