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

    private let iconImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let topStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 16
        $0.alignment = .top
    }

    private let titleLabel = UILabel().then {
        $0.font = .pretendard(size: 16, weight: .semibold)
        $0.textColor = .gray800
    }

    private let descriptionLabel = UILabel().then {
        $0.setTextWithLineHeight(text: nil, lineHeight: 21)
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .gray500
        $0.numberOfLines = 0
    }

    private let dateLabel = UILabel().then {
        $0.font = .pretendard(size: 12, weight: .regular)
        $0.textColor = .gray500
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

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
        dateLabel.text = nil
    }

    // MARK: - Set Styles

    private func setStyles() {

    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            topStackView,
            descriptionLabel,
        ].forEach { contentView.addSubview($0) }

        [
            iconImageView,
            titleLabel,
            dateLabel,
        ].forEach { topStackView.addArrangedSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(30)
        }

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(19)
        }

        dateLabel.snp.makeConstraints { make in
            make.height.equalTo(18)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
    }

    // MARK: - Methods

    func configure(item: HomeNotice) {
        titleLabel.text = item.title
        descriptionLabel.text = item.description
        dateLabel.text = item.date
        iconImageView.image = item.iconImage
        backgroundColor = item.backgroundColor
    }
}
