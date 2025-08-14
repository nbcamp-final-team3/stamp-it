//
//  MissionCategory+Extension.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit

extension MissionCategory {
    /// 이미지 파일명을 반환하는 연산 프로퍼티
    var imageName: String {
        switch self {
        case .chore: return "chore"
        case .communication: return "communication"
        case .health: return "health"
        case .learning: return "learning"
        case .custom: return "custom"
        }
    }
    
    var title: String {
        switch self {
        case .chore:
            "집안일"
        case .communication:
            "가족소통"
        case .health:
            "건강운동"
        case .learning:
            "독서학습"
        case .custom:
            "사용자정의"
        }
    }

    var image: UIImage {
        return UIImage(named: imageName) ?? UIImage()
    }

    var backgroundColor: UIColor {
        switch self {
        case .chore:
                .red100
        case .communication:
                .blue100
        case .health:
                .yellow100
        case .learning:
                .purple100
        case .custom:
                .D_7_F_4_DC
        }
    }
}
