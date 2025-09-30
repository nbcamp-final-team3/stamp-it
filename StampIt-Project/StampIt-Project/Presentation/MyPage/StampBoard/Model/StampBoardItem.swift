//
//  ProfileSection.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

enum StampBoardSection: Int, Hashable, CaseIterable {
    case summary
    case board

    var type: [[StampCellType]] {
        switch self {
        case .board:
            return [
                [.horizontal, .horizontal, .horizontal, .horizontal, .vertical],
                [.both, .horizontal, .horizontal, .horizontal, .none],
                [.horizontal, .horizontal, .horizontal, .horizontal, .vertical],
                [.both, .horizontal, .horizontal, .horizontal, .none],
                [.horizontal, .horizontal, .horizontal, .horizontal, .vertical],
                [.horizontal, .horizontal, .horizontal, .horizontal, .none],
            ]
        default: return .init()
        }
    }
}

extension StampBoardSection {
    static var column: Int { 5 }
    static var row: Int { 6 }
}

enum StampBoardItem: Hashable {
    case summary(collected: Int, completed: Int)
    case stamp(StampBoardStamp)
}

/// Dashed Line 방향 기준
enum StampCellType: Hashable {
    case horizontal
    case vertical
    case both
    case none
}
