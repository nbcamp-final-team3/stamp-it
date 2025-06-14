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
    private var type: MissionType? {
        didSet {
            toggleViewOnType()
            newTag.isHidden = type == .sended
        }
    }

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
            make.verticalEdges.equalToSuperview().inset(12)
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

    func configureAsSended(with mission: HomeSendedMission, type: MissionType) {
        self.type = type
        imageContainerView.backgroundColor = mission.category.backgroundColor
        categoryImageView.image = mission.category.image
        nameTag.updateText(with: mission.assignee)
        dateTag.updateText(with: mission.dueDate)
        if mission.isOverdue { dateTag.updateTextColor(.gray200) }
        daysLeftLabel.text = mission.daysLeft
        titleLabel.text = mission.title
        updateStatusView(for: mission.status)
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
