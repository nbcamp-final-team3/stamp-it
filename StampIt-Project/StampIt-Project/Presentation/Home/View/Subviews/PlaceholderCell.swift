//
//  PlaceholderCell.swift
//  StampIt-Project
//
//  Created by daeun on 6/12/25.
//

import UIKit
import SnapKit
import Then

final class PlaceholderCell: UICollectionViewCell {

    // MARK: - Properties

    static let identifier = "PlaceholderCell"

    // MARK: - UI Components

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = ._000000
    }

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

    // MARK: - Set Styles

    private func setStyles() {
        contentView.backgroundColor = .gray25
        contentView.layer.cornerRadius = 8
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        contentView.addSubview(titleLabel)
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - Methods

    func configure(with title: String) {
        titleLabel.text = title
    }
}
