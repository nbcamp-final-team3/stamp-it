//
//  StickerUtil.swift
//  StampIt-Project
//
//  Created by kingj on 7/3/25.
//

import Foundation

struct StickerUtil {
    
    /// 지그재그 순서로 스티커 배열 생성
    static func makeZigzagOrder(
        from stickers: [StampBoardStamp],
        columns: Int,
        pinNumber: Int
    ) -> [StampBoardStamp] {
        let totalStickerCount = StampBoardSection.totalStamp
        
        /// 총 totalStickerCount 개의 스탬프 배열 생성 (부족하면 Empty sticker 생성)
        let totalStickers: [StampBoardStamp] = {
            (0..<totalStickerCount).map { index in
                
                /// Empty stickers 배열 일 때 default stamp 생성
                if stickers.count == .zero {
                    return makeEmptySticker(with: pinNumber)
                } else {
                    /// stickers 배열이 1 이상, totalStickerCount 이하 일 경우
                    if index < stickers.count {
                        return stickers[index]
                    } else {
                        return makeEmptySticker(with: pinNumber)
                    }
                }
            }
        }()
        
        /// 행 단위로 나눠서 지그재그 정렬
        let rows = stride(from: 0, to: totalStickers.count, by: columns)
            .map {
                Array(totalStickers[$0..<min($0 + columns, totalStickers.count)])
            }
        
        let zigzagOrdered = rows.enumerated().flatMap { (index, row) in
            index.isMultiple(of: 2) ? row : row.reversed()
        }
        
        /// 지그재그 순서에 맞춰 zigzagIndex 부여
        let finalStickers = zigzagOrdered.enumerated().map { (index, sticker) -> StampBoardStamp in
            var zigzagIndexAdded = sticker
            zigzagIndexAdded.zigzagIndex = index
            return zigzagIndexAdded
        }
        
        return finalStickers
    }
    
    /// 빈 회색 스티커 생성
    static func makeEmptySticker(
        with pinNumber: Int,
        zigzagIndex: Int? = nil
    ) -> StampBoardStamp {
        
        // TODO: type 체크
        
        StampBoardStamp(
            userID: "Unknown",
            stickerID: "\(UUID())",
            groupID: "Unknown",
            month: "0000-00",
            type: .stampGray,
            pinNumber: pinNumber,
            createdAt: Date(),
            missionID: "Unknown",
            maxStickers: .zero,
            assignedBy: "Unknown",
            zigzagIndex: zigzagIndex ?? -1,
            shouldBlur: false,
        )
    }
    
    /// 스탬프판 초기값 생성
    static func initialize() -> [[StampBoardStamp]] {
        [
            (0..<StampBoardSection.totalStamp).map {
                StickerUtil.makeEmptySticker(with: 1, zigzagIndex: $0)
            }
        ]
    }
}
