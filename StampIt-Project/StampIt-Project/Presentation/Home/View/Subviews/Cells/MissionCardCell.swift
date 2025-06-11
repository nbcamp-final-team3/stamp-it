//
//  MissionCardCell.swift
//  StampIt-Project
//
//  Created by daeun on 6/11/25.
//

import UIKit
import SnapKit
import Then

final class MissionCardCell: UICollectionViewCell {

    // MARK: - Properties

    static let identifier = "MissionCardCell"

    // MARK: - UI Components

    private let categoryImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let tagStackView = UIStackView().then {
        $0.spacing = 4
    }

    private let dateTag = TagView(type: .filledLight)

    private let assignerTag = TagView(type: .filledLight)

    private let titleLabel = UILabel().then {
        $0.font = .pretendard(size: 20, weight: .semibold)
        $0.textColor = ._000000
        $0.textAlignment = .center
    }

    private let completeButton = UIButton().then {
        var config = UIButton.Configuration.filled()

        // attributedTitle
        let attributed = AttributedString("미션 완료하기")
        var container = AttributeContainer()
        container.font = .pretendard(size: 16, weight: .regular)
        let styled = attributed.settingAttributes(container)
        config.attributedTitle = styled

        // color
        config.baseBackgroundColor = .FFFFFF
        config.baseForegroundColor = ._1_E_1_E_1_E

        config.contentInsets = .init(top: 6, leading: 20, bottom: 6, trailing: 20)

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

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: contentView.layer.cornerRadius
        ).cgPath
    }

    // MARK: - Set Styles

    private func setStyles() {
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.16
        layer.shadowRadius = 4
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            categoryImageView,
            tagStackView,
            titleLabel,
            completeButton
        ].forEach { contentView.addSubview($0) }

        [
            dateTag,
            assignerTag,
        ].forEach { tagStackView.addArrangedSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        categoryImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
            make.size.equalTo(100)
        }

        tagStackView.snp.makeConstraints { make in
            make.top.equalTo(categoryImageView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(tagStackView.snp.bottom).offset(4)
            make.directionalHorizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(30)
        }

        completeButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.directionalHorizontalEdges.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
            make.height.equalTo(36)
        }
    }

    // MARK: - Methods

    func configure(category: MissionCategory, date: String, assigner: String, title: String) {
        categoryImageView.image = category.image
        contentView.backgroundColor = category.backgroundColor
        dateTag.configure(with: date)
        assignerTag.configure(with: assigner)
        titleLabel.text = title
    }
}
