//
//  DashboardHeader.swift
//  StampIt-Project
//
//  Created by daeun on 6/12/25.
//

import UIKit
import SnapKit
import Then

final class DashboardHeader: UICollectionReusableView {

    // MARK: - Properties

    static let identifier = "DashboardHeader"

    // MARK: - UI Components

    private let labelStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 0
    }

    private let titleLabel = UILabel().then {
        $0.font = .pretendard(size: 24, weight: .medium)
        $0.textColor = ._000000
    }

    private let descriptionLabel = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = ._000000
    }

    private let moreButton = UIButton().then {
        var config = UIButton.Configuration.plain()

        // attributedTitle
        let attributed = AttributedString("더보기")
        var container = AttributeContainer()
        container.font = UIFont.pretendard(size: 14, weight: .medium)
        let styled = attributed.settingAttributes(container)
        config.attributedTitle = styled
        config.image = .chevronForward
        config.imagePadding = 0
        config.imagePlacement = .trailing

        // color
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .gray500

        config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

        $0.configuration = config
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
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            labelStackView,
            moreButton,
        ].forEach { addSubview($0) }

        [
            titleLabel,
            descriptionLabel,
        ].forEach { labelStackView.addArrangedSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        labelStackView.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(36)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.height.equalTo(21)
        }

        moreButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview()
        }
    }

    // MARK: - Methods

    func configure(title: String, description: String) {
        titleLabel.text = title
        descriptionLabel.text = description
    }
}
