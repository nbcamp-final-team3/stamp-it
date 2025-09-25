//
//  StampUtil.swift
//  StampIt-Project
//
//  Created by kingj on 7/3/25.
//

import Foundation

struct StampUtil {
    
    /// 지그재그 순서로 스티커 배열 생성
    static func makeZigzagOrder(
        from stamps: [StampBoardStamp],
        columns: Int,
        pinNumber: Int
    ) -> [StampBoardStamp] {
        let totalStampCount = Stamp.totalStamp

        /// 총 totalStampCount 개의 스탬프 배열 생성 (부족하면 Empty stamp 생성)
        let totalStamps: [StampBoardStamp] = {
            (0..<totalStampCount).map { index in
                
                /// Empty stamps 배열 일 때 default stamp 생성
                if stamps.count == .zero {
                    return makeEmptyStamp(with: pinNumber)
                } else {
                    /// stamps 배열이 1 이상, totalStampCount 이하 일 경우
                    if index < stamps.count {
                        return stamps[index]
                    } else {
                        return makeEmptyStamp(with: pinNumber)
                    }
                }
            }
        }()
        
        /// 행 단위로 나눠서 지그재그 정렬
        let rows = stride(from: 0, to: totalStamps.count, by: columns)
            .map {
                Array(totalStamps[$0..<min($0 + columns, totalStamps.count)])
            }
        
        let zigzagOrdered = rows.enumerated().flatMap { (index, row) in
            index.isMultiple(of: 2) ? row : row.reversed()
        }
        
        /// 지그재그 순서에 맞춰 zigzagIndex 부여
        let finalStamps = zigzagOrdered.enumerated().map { (index, stamp) -> StampBoardStamp in
            var zigzagIndexAdded = stamp
            zigzagIndexAdded.zigzagIndex = index
            return zigzagIndexAdded
        }
        
        return finalStamps
    }
    
    /// 빈 회색 스티커 생성
    static func makeEmptyStamp(
        with pinNumber: Int,
        zigzagIndex: Int? = nil,
        now: Date = Date(),
        uuidString: String = UUID().uuidString,
    ) -> StampBoardStamp {
        .init(
            userID: DefaultStamp.userID,
            stampID: uuidString,
            groupID: DefaultStamp.groupID,
            month: DefaultStamp.month,
            type: .gray,
            pinNumber: pinNumber,
            createdAt: now,
            missionID: DefaultStamp.missionID,
            maxStamps: DefaultStamp.maxStamps,
            assignedBy: DefaultStamp.assignedBy,
            zigzagIndex: zigzagIndex ?? DefaultStamp.zigzagIndex,
            shouldBlur: false,
        )
    }
    
    /// 스탬프판 초기값 생성
    static func initialize() -> [[StampBoardStamp]] {
        [
            (0..<Stamp.totalStamp).map {
                StampUtil.makeEmptyStamp(with: 1, zigzagIndex: $0)
            }
        ]
    }
}
