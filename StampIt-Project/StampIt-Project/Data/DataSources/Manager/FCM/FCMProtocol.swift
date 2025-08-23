//
//  FCMProtocol.swift
//  StampIt-Project
//
//  Created by 윤주형 on 8/23/25.
//

import RxSwift
import Foundation

protocol FCMManagerProtocol {
    // FCM 토큰 관리
//    func getFCMToken() -> Observable<String>
    
    // 단순한 토큰 관리 (새로운 구조)
    func upsertToken(_ token: String, for userId: String)
    
    // 토큰 갱신 (로그인 시 사용)
//    func refreshFCMTokenForUser(userId: String) -> Observable<Void>
    
}
