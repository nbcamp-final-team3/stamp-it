//
//  FCMProtocol.swift
//  StampIt-Project
//
//  Created by 윤주형 on 7/29/25.
//

import RxSwift
import Foundation

protocol FCMManagerProtocol {
    // FCM 토큰 관리 // 임시 주석 처리
    func getFCMToken() -> Observable<String>
    
//    // 토큰 갱신 (로그인 시 사용) // 로그인 시 자동 갱신 중
    func refreshFCMTokenForUser(userId: String) -> Observable<Void>
    
    // 토큰 저장/조회
    func saveFCMTokenToUser(userId: String, token: String) -> Observable<Void>
    func getFCMTokenFromUser(userId: String) -> Observable<String?>
    
    // 그룹 멤버들의 FCM 토큰만 조회
    func getGroupMemberFCMTokens(groupId: String) -> Observable<[String]>
} 
