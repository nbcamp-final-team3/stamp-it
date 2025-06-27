//
//  NSCollectionLayoutSection+Extension.swift
//  StampIt-Project
//
//  Created by daeun on 6/25/25.
//

import UIKit

extension NSCollectionLayoutSection {
    /// 칩 형태의 필터링 섹션 레이아웃
    static func createFilterSection(
        withHeader header: NSCollectionLayoutBoundarySupplementaryItem? = nil,
        insets: NSDirectionalEdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16),
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(70),
                                              heightDimension: .estimated(32))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(70),
                                               heightDimension: .estimated(32))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = insets
        section.orthogonalScrollingBehavior = .continuous

        if let header {
            section.boundarySupplementaryItems = [header]
        }

        return section
    }
}
