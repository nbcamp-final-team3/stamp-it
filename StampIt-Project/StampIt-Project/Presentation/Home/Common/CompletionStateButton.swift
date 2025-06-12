//
//  CompletionStateButton.swift
//  StampIt-Project
//
//  Created by daeun on 6/11/25.
//

import UIKit
import SnapKit
import Then

final class CompletionStateButton: UIControl {

    // MARK: - Properties

    private var status: MissionStatus {
        didSet {
            setStyles()
        }
    }

    // MARK: - UIComponent

    private let containerStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 2
        $0.alignment = .center
        $0.isUserInteractionEnabled = false
    }

    private let markImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let titleLabel = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .semibold)
    }

    // MARK: - Init

    init(status: MissionStatus) {
        self.status = status
        super.init(frame: .zero)
        setStyles()
        setHierarchy()
        setConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Set Styles

    private func setStyles() {
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor
        layer.cornerRadius = 8
        backgroundColor = baseColor

        markImageView.isHidden = status == .assigned
        if let symbol {
            markImageView.image = symbol
            markImageView.tintColor = textColor
        }

        titleLabel.text = text
        titleLabel.textColor = textColor
    }

    // MARK: - Set Styles

    private func setHierarchy() {
        addSubview(containerStackView)

        [
            markImageView,
            titleLabel,
        ].forEach { containerStackView.addArrangedSubview($0) }
    }

    // MARK: - Set Styles

    private func setConstraints() {
        containerStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(4.5)
            make.directionalHorizontalEdges.equalToSuperview().inset(8)
        }

        markImageView.snp.makeConstraints { make in
            make.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
    }

    // MARK: - Methods

    func updateStatus(to status: MissionStatus) {
        self.status = status
    }
}

extension CompletionStateButton {
    private var borderWidth: CGFloat {
        switch status {
        case .assigned, .failed: 0
        case .completed: 1
        }
    }

    private var borderColor: CGColor? {
        switch status {
        case .assigned, .failed: nil
        case .completed: UIColor.red200.cgColor
        }
    }

    private var baseColor: UIColor {
        switch status {
        case .assigned: .red50
        case .completed: .clear
        case .failed: .gray25
        }
    }

    private var text: String {
        switch status {
        case .assigned: "완료하기"
        case .completed: "완료"
        case .failed: "만료"
        }
    }

    private var textColor: UIColor {
        switch status {
        case .assigned, .completed: .red400
        case .failed: .gray200
        }
    }

    private var symbol: UIImage? {
        switch status {
        case .assigned: nil
        case .completed: .checkRed
        case .failed: .xGray200
        }
    }
}
