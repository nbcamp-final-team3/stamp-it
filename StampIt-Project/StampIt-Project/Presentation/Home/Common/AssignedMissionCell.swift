//
//  AssignedMissionCell.swift
//  StampIt-Project
//
//  Created by daeun on 6/11/25.
//

import UIKit
import SnapKit
import Then

final class AssignedMissionCell: UICollectionViewCell {

    // MARK: - Properties

    static let identifier = "AssignedMissionCell"
    private let type: MissionType

    // MARK: - UI Components

    private let imageContainerView = UIView().then {
        $0.layer.cornerRadius = 8
    }

    private let categoryImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let tagStackView = UIStackView().then {
        $0.spacing = 4
    }

    private let newTag = TagView(type: .outlined).then {
        $0.updateText(with: "New")
    }

    private let nameTag = TagView(type: .filledBold)

    private let dateTag = TagView(type: .filledBold)

    private let titleLabel = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .gray800
    }

    private let statusView = UIView()

    private let daysLeftLabel = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .gray500
    }

    private let statusImage = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let statusLabel = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .semibold)
        $0.textAlignment = .right
    }

    private let statusButton = CompletionStateButton(status: .assigned)

    private let separatorView = UIView().then {
        $0.backgroundColor = .gray50
    }

    // MARK: - Life Cycles

    init(type: MissionType) {
        self.type = type
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
        toggleViewOnType()
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            imageContainerView,
            tagStackView,
            titleLabel,
            statusView,
            statusButton,
            separatorView,
        ].forEach{ contentView.addSubview($0) }

        [
            categoryImageView,
        ].forEach { imageContainerView.addSubview($0) }

        [
            newTag,
            nameTag,
            dateTag,
            ].forEach { tagStackView.addArrangedSubview($0) }
        
        [
            daysLeftLabel,
            statusImage,
            statusLabel,
        ].forEach { statusView.addSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        imageContainerView.snp.makeConstraints { make in
            make.verticalEdges.leading.equalToSuperview().inset(12)
            make.leading.equalToSuperview()
            make.size.equalTo(50)
        }

        categoryImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(35)
        }

        tagStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(13.5)
            make.leading.equalTo(imageContainerView.snp.trailing).offset(12)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(tagStackView.snp.bottom).offset(4)
            make.leading.equalTo(imageContainerView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(80)
            make.bottom.equalToSuperview().inset(13.5)
            make.height.equalTo(21)
        }

        statusView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(15.5)
            make.trailing.equalToSuperview()
            make.width.equalTo(80)
        }

        daysLeftLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.height.equalTo(21)
        }

        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(daysLeftLabel.snp.bottom).offset(3.5)
            make.trailing.equalToSuperview()
            make.height.equalTo(17)
        }

        statusImage.snp.makeConstraints { make in
            make.top.equalTo(daysLeftLabel.snp.bottom).offset(2)
            make.trailing.equalTo(statusLabel.snp.leading).offset(-2)
            make.size.equalTo(20)
        }

        statusButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        separatorView.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.directionalHorizontalEdges.bottom.equalToSuperview()
        }
    }

    // MARK: - Methods

    func configureCell(
        category: MissionCategory,
        name: String,
        dueDate: String,
        daysLeft: String,
        title: String,
        status: MissionStatus,
        isNew: Bool = false,
        isOverdue: Bool = false,
    ) {
        imageContainerView.backgroundColor = category.backgroundColor
        categoryImageView.image = category.image
        newTag.isHidden = !isNew || type == .sended
        nameTag.updateText(with: name)
        dateTag.updateText(with: dueDate)
        if isOverdue { dateTag.updateTextColor(.gray200) }
        daysLeftLabel.text = daysLeft
        titleLabel.text = title

        switch type {
        case .received:
            statusButton.updateStatus(to: status)
        case .sended:
            updateStatusView(for: status)
        }
    }

    private func toggleViewOnType() {
        statusButton.isHidden = type == .sended
        statusView.isHidden = type == .received
    }

    private func updateStatusView(for status: MissionStatus) {
        statusLabel.isHidden = status == .assigned
        statusLabel.text = status.text
        statusLabel.textColor = status == .completed ? .blue400 : .gray400

        statusImage.image = status == .completed ? .checkBlue : .xGray400
        statusImage.isHidden = status == .assigned
        statusImage.tintColor = status == .completed ? .blue400 : .gray400
    }
}

extension AssignedMissionCell {
    enum MissionType {
        case received
        case sended
    }
}
