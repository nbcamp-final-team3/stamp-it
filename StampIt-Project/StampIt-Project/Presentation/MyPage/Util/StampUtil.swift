//
//  StampUtil.swift
//  StampIt-Project
//
//  Created by kingj on 7/3/25.
//

import Foundation

struct StampUtil {
    /// 새 스탬프 하이라이팅 애니메이션을 위한 ID 생성
    static func makeRealID(
        with stampsByPage: [[StampBoardStamp]]
    ) -> Set<StampCellIdentity> {
        var realIdSet = Set<StampCellIdentity>()
        for (page, stamps) in stampsByPage.enumerated() {
            for index in 0..<min(stamps.count, Stamp.totalStamp) {
                realIdSet.insert(StampCellIdentity(page: page, stampIndex: index))
            }
        }
        return realIdSet
    }

    /// Identity 별 Appearance 생성
    static func makeBoardAppearance(
        with stampsByPage: [[StampBoardStamp]] = StampUtil.makeEmptyBoard(),
        cache: [StampCellIdentity: StampCellAppearance] = .init(),
        isInitialBoardLoaded: Bool = false,
        isBeforeInitialLoaded: Bool = false
    ) -> [StampCellIdentity: StampCellAppearance] {
        let totalPage = stampsByPage.count
        var appearance: [StampCellIdentity: StampCellAppearance] = [:]
        appearance.reserveCapacity(stampsByPage.count * Stamp.totalStamp)

        for (page, stamps) in stampsByPage.enumerated() {
            let visualIndex = totalPage - 1 - page // 페이지별 스탬프 색상 지정 (2페이지면: (0->1), (1->0))
            let color = isBeforeInitialLoaded ? .gray : StampType.from(visualIndex)

            for index in 0..<Stamp.totalStamp {
                let identity = StampCellIdentity(page: page, stampIndex: index)
                if index < stamps.count { // real
                    var isHighlighted: Bool = false
                    if isInitialBoardLoaded {// 기존 스탬프
                        if let previous = cache[identity] {
                            if previous.color != .gray && previous.isHighlighted {
                                isHighlighted = true
                            }
                        }
                    } else {
                        isHighlighted = true
                    }
                    appearance[identity] = StampCellAppearance(
                        color: color,
                        isHighlighted: isHighlighted
                    )
                } else { // placeholder
                    appearance[identity] = StampCellAppearance(
                        color: .gray,
                        isHighlighted: true
                    )
                }
            }
        }
        return appearance
    }

    /// Page 별 Identity, Content 생성
    static func makeBoardContent(
        with stampsByPage: [[StampBoardStamp]]? = nil
    ) -> [StampCellIdentity: StampCellContent] {
        let totalPage = stampsByPage?.count ?? 1
        var content: [StampCellIdentity: StampCellContent] = [:]
        content.reserveCapacity(totalPage * Stamp.totalStamp)

        guard let stampsByPage else {
            for index in 0..<Stamp.totalStamp {
                let identity = StampCellIdentity(page: .zero, stampIndex: index)
                content[identity] = .placeholder
            }
            return content
        }
        let zigzagIndices: [Int] = makeZigZagIndices()
        let ordered: [[StampBoardStamp]] = makeZigzagOrder(from: stampsByPage)

        for (page, stamps) in ordered.enumerated() {
            for index in 0..<Stamp.totalStamp {
                let identity = StampCellIdentity(page: page, stampIndex: index)
                if index < stampsByPage[page].count {
                    content[identity] = .real(stamps[zigzagIndices[index]])
                } else {
                    content[identity] = .placeholder
                }
            }
        }
        return content
    }

    /// View 그리기용 Identity 배열 만들기
    static func makeBoardIdentity(_ totalPage: Int = 1) -> [[StampCellIdentity]] {
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
            .map { Array($0..<min($0 + columns, totalStamp)) }
        let zigzagOrdered = numbers.enumerated().map { (index, row) in
            index.isMultiple(of: 2) ? row : row.reversed()
        }
        return zigzagOrdered.flatMap { $0 }
    }

    /// 빈 회색 스티커 생성
    static func makeEmptyStamp(
        now: Date = Date(),
        uuidString: String = UUID().uuidString,
    ) -> StampBoardStamp {
        .init(
            userID: DefaultStamp.userID,
            stampID: uuidString,
            groupID: DefaultStamp.groupID,
            month: DefaultStamp.month,
            createdAt: now,
            missionID: DefaultStamp.missionID,
            maxStamps: DefaultStamp.maxStamps,
            assignedBy: DefaultStamp.assignedBy,
        )
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
        for stamps in stampsByPage {
            if stamps.count == .zero {
                tempStampsByPage.append(
                    (0..<totalStamp).map { _ in makeEmptyStamp() }
                )
                return tempStampsByPage
            } else {
                var tempStamp: [StampBoardStamp] = .init()
                for index in 0..<totalStamp {
                    /// stamps 배열이 1 이상, totalStamp 개수 이하 일 경우
                    if index < stamps.count {
                        tempStamp.append(stamps[index])
                    } else {
                        tempStamp.append(makeEmptyStamp())
                    }
                }
                tempStampsByPage.append(tempStamp)
            }
        }

        /// 만들어진 스탬프 배열 지그재그 순서로 정렬
        for page in tempStampsByPage {
            /// 한 페이지 안의 columns 개수 만큼의 스탬프를 한 행으로 나누기
            let divideByRow = stride(from: 0, to: totalStamp, by: columns)
                .map {
                    Array(page[$0..<min($0 + columns, totalStamp)])
                }
            /// 0-indexed, 홀수 행 일 경우 순서 뒤집기
            let zigzagOrdered = divideByRow.enumerated().flatMap { (index, row) in
                index.isMultiple(of: 2) ? row : row.reversed()
            }
            ordered.append(zigzagOrdered)
        }
        return ordered
    }

    /// 초기값 생성 - 스탬프판
    static func makeEmptyBoard() -> [[StampBoardStamp]] {
        [(0..<Stamp.totalStamp).map { _ in StampUtil.makeEmptyStamp() }]
    }

    /// 초기값 생성 - StampBoardViewState
    static func makeDefaultViewState() -> StampBoardViewState {
        StampBoardViewState(
            collectdStamp: .zero,
            completedBoard: .zero,
            stampContent: StampUtil.makeBoardContent(),
            stampAppearance: StampUtil.makeBoardAppearance(isBeforeInitialLoaded: true),
            stampIdentityByPage: StampUtil.makeBoardIdentity()
        )
    }
}
