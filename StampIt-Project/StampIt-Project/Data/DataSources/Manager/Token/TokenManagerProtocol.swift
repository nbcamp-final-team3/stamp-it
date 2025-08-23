//
//  TokenManagerProtocol.swift
//  StampIt-Project
//
//  Created by 윤주형 on 8/23/25.
//

import Foundation
import RxSwift

protocol TokenManagerProtocol {
    /// 사용자의 FCM 토큰 저장/업데이트
    func saveOrUpdateToken(userId: String, fcmToken: String) -> Observable<Void>
    
    /// 사용자의 FCM 토큰 조회
    func getActiveToken(userId: String) -> Observable<String?>
    
    /// 그룹 멤버들의 FCM 토큰 조회
    func getGroupMemberActiveTokens(groupId: String) -> Observable<[String]>
    
    
    /// 사용자의 모든 토큰 삭제 (계정 삭제 시)
    func deleteAllTokens(userId: String) -> Observable<Void>
}
