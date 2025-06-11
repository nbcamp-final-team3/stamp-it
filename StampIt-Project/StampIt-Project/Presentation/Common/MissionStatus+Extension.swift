//
//  MissionStatus+Extension.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import UIKit

extension MissionStatus {
    var text: String {
        switch self {
        case .assigned:
            ""
        case .completed:
            "완료"
        case .failed:
            "만료"
        }
    }

    // TODO: Color 추가
}
