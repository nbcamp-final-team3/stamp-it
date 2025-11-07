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
    static func initializeEmptyBoard() -> [[StampBoardStamp]] {
        [
            (0..<Stamp.totalStamp).map {
                StampUtil.makeEmptyStamp(with: 1, zigzagIndex: $0)
            }
        ]
    }

    static func makeStampBoardContent(
        with stampsByPage: [[StampBoardStamp]] = StampUtil.initializeEmptyBoard()
    ) -> [StampCellIdentity: StampCellContent] {
        let zigzagIndices: [Int] = makeZigZagIndices()
        let ordered: [[StampBoardStamp]] = makeZigzagOrder(from: stampsByPage)
        var content: [StampCellIdentity: StampCellContent] = [:]
        content.reserveCapacity(stampsByPage.count * Stamp.totalStamp)

        for (page, stamps) in ordered.enumerated() {
            for index in zigzagIndices {
                let identity = StampCellIdentity(page: page, stampIndex: index)
                if index < stamps.count {
                    content[identity] = .real(stamps[index])
                } else {
                    content[identity] = .placeholder
                }
            }
        }
        return content
    }

    /// View 그리기용 Identity 배열 만들기
    static func makeStampBoardIdentity(_ totalPage: Int) -> [[StampCellIdentity]] {
        var identityByPage: [[StampCellIdentity]] = .init()
        let zigzagIndices: [Int] = makeZigZagIndices()

        for page in 0..<totalPage {
            var identities: [StampCellIdentity] = .init()
            for index in zigzagIndices {
                identities.append(StampCellIdentity(page: page, stampIndex: index))
            }
            identityByPage.append(identities)
        }
        return identityByPage
    }

    /// `StampCellIdentity` 만들기 용 지그재그 패턴 Index
    /// return 예시: [0...4, 9...5, 10...14, 19...15 ... ]
    static func makeZigZagIndices(
        totalStamp: Int = Stamp.totalStamp,
        columns: Int = StampBoardSection.column
    ) -> [Int] {
        let numbers: [[Int]] = stride(from: 0, to: totalStamp, by: columns)
            .map {
                Array($0..<min($0 + columns, totalStamp))
            }
        let zigzagOrdered = numbers.enumerated().map { (index, row) in
            index.isMultiple(of: 2) ? row : row.reversed()
        }
        return zigzagOrdered.flatMap { $0 }
    }

    /// 실제 데이터를 지그재그 순서로 변환
    static func makeZigzagOrder(
        from stampsByPage: [[StampBoardStamp]],
        totalStamp: Int = Stamp.totalStamp,
        columns: Int = StampBoardSection.column
    ) -> [[StampBoardStamp]] {
        var tempStampsByPage: [[StampBoardStamp]] = .init()
        var ordered: [[StampBoardStamp]] = .init()

        /// totalStamp 개수 맞춰서 스탬프 생성
        for (page, stamps) in stampsByPage.enumerated() {
            if stamps.count == .zero {
                tempStampsByPage.append(
                    (0..<totalStamp).map { _ in makeEmptyStamp(with: page) }
                )
                return tempStampsByPage
            } else {
                var tempStamp: [StampBoardStamp] = .init()
                for index in 0..<totalStamp {
                    /// stamps 배열이 1 이상, totalStamp 개수 이하 일 경우
                    if index < stamps.count {
                        tempStamp.append(stamps[index])
                    } else {
                        tempStamp.append(makeEmptyStamp(with: page))
                    }
                }
                tempStampsByPage.append(tempStamp)
            }
        }

        /// 만들어진 스탬프 배열 지그재그 순서로 정렬
        for (page, stamps) in tempStampsByPage.enumerated() {
            /// 한 페이지 안의 columns 개수 만큼의 스탬프를 한 행으로 나누기
            let divideByRow = stride(from: 0, to: totalStamp, by: columns)
                .map {
                    Array(stamps[$0..<min($0 + columns, totalStamp)])
                }
            /// 0-indexed, 홀수 행 일 경우 순서 뒤집기
            let zigzagOrdered = divideByRow.enumerated().flatMap { (index, row) in
                index.isMultiple(of: 2) ? row : row.reversed()
            }
            ordered.append(zigzagOrdered)
        }
        return ordered
    }
}
