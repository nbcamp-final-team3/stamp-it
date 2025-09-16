//
//  FCMProtocol.swift
//  StampIt-Project
//
//  Created by 윤주형 on 8/23/25.
//

import RxSwift
import Foundation

protocol FCMManagerProtocol {
    // 단순한 토큰 관리 (새로운 구조)
    func upsertToken(_ token: String, for userId: String)
    
}
