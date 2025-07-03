//
//  CompletionStateButton.swift
//  StampIt-Project
//
//  Created by daeun on 6/11/25.
//

import UIKit
import SnapKit
import Then

final class MissionStateButton: UIControl {

    // MARK: - Properties

    private var status: Status {
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
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override var intrinsicContentSize: CGSize {
        let viewSize = containerStackView.intrinsicContentSize
        let width = 64.0
        let height = viewSize.height + 4.5 * 2
        return CGSize(width: width, height: height)
    }

    // MARK: - Init

    init(status: Status) {
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
        layer.cornerRadius = 8
        backgroundColor = baseColor

        markImageView.isHidden = status == .assigned || status == .completed(isCancelable: true)
        if let symbol {
            markImageView.image = symbol
            markImageView.tintColor = textColor
        }

        titleLabel.text = text
        titleLabel.textColor = textColor
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        addSubview(containerStackView)

        [
            markImageView,
            titleLabel,
        ].forEach { containerStackView.addArrangedSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        containerStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(4.5)
            make.centerX.equalToSuperview()
        }

        markImageView.snp.makeConstraints { make in
            make.size.equalTo(20)
        }

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
    }

    // MARK: - Methods

    func updateStatus(to status: MissionStatus, _ isCancelable: Bool) {
        self.status = Status(status, isCancelable)
    }
}

extension MissionStateButton {
    enum Status: Equatable {
        case assigned
        case completed(isCancelable: Bool)
        case failed

        init(_ missionStatus: MissionStatus, _ isCancelable: Bool) {
            switch missionStatus {
            case .assigned:
                self = .assigned
            case .completed:
                self = .completed(isCancelable: isCancelable)
            case .failed:
                self = .failed
            }
        }
    }

    private var baseColor: UIColor {
        switch status {
        case .assigned: .red50
        case .completed(isCancelable: true): .gray25
        default: .clear
        }
    }

    private var text: String {
        switch status {
        case .assigned: "완료하기"
        case .completed(isCancelable: true): "완료함"
        case .completed(isCancelable: false): "완료"
        case .failed: "만료"
        }
    }

    private var textColor: UIColor {
        switch status {
        case .assigned: .red400
        case .completed(isCancelable: true), .failed: .gray200
        case .completed(isCancelable: false): .red200
        }
    }

    private var symbol: UIImage? {
        switch status {
        case .completed(isCancelable: false): .checkRed200
        case .failed: .xGray200
        default: nil
        }
    }
}
