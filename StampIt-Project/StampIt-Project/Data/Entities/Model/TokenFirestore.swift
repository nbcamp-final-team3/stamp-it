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

// MARK: - Domain Model 변환
extension TokenFirestore {
    func toDomainModel() -> FCMToken {
        return FCMToken(
            tokenId: self.tokenId,
            userId: self.userId,
            fcmToken: self.fcmToken
        )
    }
}

// MARK: - Domain → Infrastructure 변환
extension FCMToken {
    func toFirestoreModel() -> TokenFirestore {
        return TokenFirestore(
            tokenId: self.tokenId,
            userId: self.userId,
            fcmToken: self.fcmToken
        )
    }
}

