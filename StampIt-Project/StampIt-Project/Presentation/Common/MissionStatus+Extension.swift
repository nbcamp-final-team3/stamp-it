//
//  MissionStatus+Extension.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation

extension MissionStatus {
    var text: String {
        switch self {
        case .asigned:
            "미완"
        case .completed:
            "완료"
        case .failed:
            "실패"
        }
    }

    // TODO: Color 추가
}
