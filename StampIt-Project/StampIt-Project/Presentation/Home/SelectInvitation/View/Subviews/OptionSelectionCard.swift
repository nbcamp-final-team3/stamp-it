//
//  OptionSelectionCard.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxRelay

final class OptionSelectionCard: UIControl {

    // MARK: - Properties

    override var isSelected: Bool {
        didSet {
            setStyles()
        }
    }

    // MARK: - UIComponent

    private let labelStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 2
    }

    private let titleLabel = UILabel().then {
        let size: CGFloat = 16
        $0.setTextWithLineHeight(text: nil, lineHeight: size * 1.2)
        $0.font = .pretendard(size: size, weight: .semibold)
        $0.textColor = ._000000
    }

    private let subtitleLabel = UILabel().then {
        let size: CGFloat = 14
        $0.setTextWithLineHeight(text: nil, lineHeight: size * 1.5)
        $0.font = .pretendard(size: size, weight: .medium)
        $0.textColor = ._777777
    }

    // MARK: - Init

    init(type: InvitationType) {
        super.init(frame: .zero)
        setStyles()
        setHierarchy()
        setConstraints()
        titleLabel.text = type.title
        subtitleLabel.text = type.description
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Set Styles

    private func setStyles() {
        backgroundColor = isSelected ? .red50 : .FFFFFF
        layer.borderColor = isSelected ? UIColor.red400.cgColor : UIColor.gray50.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 12
    }

    // MARK: - Set Styles

    private func setHierarchy() {
        [
            labelStackView
        ].forEach { addSubview($0) }

        [
            titleLabel,
            subtitleLabel,
        ].forEach { labelStackView.addArrangedSubview($0) }
    }

    // MARK: - Set Styles

    private func setConstraints() {
        labelStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(12)
            make.directionalHorizontalEdges.equalToSuperview().inset(16)
        }
    }
}
