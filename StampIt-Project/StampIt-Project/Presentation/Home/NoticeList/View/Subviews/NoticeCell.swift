//
//  NoticeCell.swift
//  StampIt-Project
//
//  Created by daeun on 7/21/25.
//

import UIKit
import SnapKit
import Then

final class NoticeCell: UICollectionViewCell {

    // MARK: - Properties

    static let identifier = "NoticeCell"

    // MARK: - UI Components


    // MARK: - Life Cycles

    override init(frame: CGRect) {
        super.init(frame: frame)
        setStyles()
        setHierarchy()
        setConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    // MARK: - Set Styles

    private func setStyles() {

    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
    }

    // MARK: - Set Constraints

    private func setConstraints() {

    }

    // MARK: - Methods

}
