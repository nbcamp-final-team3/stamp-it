//
//  AssignedMissionCell.swift
//  StampIt-Project
//
//  Created by daeun on 6/11/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class AssignedMissionCell: UICollectionViewCell {

    // MARK: - Actions

    let didTapStatusButton = PublishRelay<Void>()

    // MARK: - Properties

    static let identifier = "AssignedMissionCell"
    private var type: MissionType? {
        didSet {
            toggleViewOnType()
            newTag.isHidden = type == .sended
        }
    }
    var disposeBag = DisposeBag()

    // MARK: - UI Components

    private let contentStackView = UIStackView().then {
        $0.spacing = 12
        $0.alignment = .center
    }

    private let imageContainerView = UIView().then {
        $0.layer.cornerRadius = 8
    }

    private let categoryImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }

    private let tagAndTitleStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .leading
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
        $0.setTextWithLineHeight(text: nil, lineHeight: 21)
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .gray800
        $0.numberOfLines = 0
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
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        setStyles()
        setHierarchy()
        setConstraints()
        bind()
    }

    // MARK: - Set Styles

    private func setStyles() {

    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            contentStackView,
            statusView,
            statusButton,
            separatorView,
        ].forEach{ contentView.addSubview($0) }

        [
            imageContainerView,
            tagAndTitleStackView,
        ].forEach { contentStackView.addArrangedSubview($0) }

        [
            categoryImageView,
        ].forEach { imageContainerView.addSubview($0) }

        [
            tagStackView,
            titleLabel,
        ].forEach { tagAndTitleStackView.addArrangedSubview($0) }

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
        contentStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(12)
            make.leading.equalToSuperview()
            make.trailing.equalTo(statusButton.snp.leading).offset(-20)
        }

        imageContainerView.snp.makeConstraints { make in
            make.size.equalTo(50)
        }

        categoryImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(35)
        }

        statusView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(15.5)
            make.trailing.equalToSuperview()
            make.width.equalTo(46)
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

    // MARK: - Bind

    private func bind() {
        statusButton.rx.controlEvent(.touchUpInside)
            .bind(to: didTapStatusButton)
            .disposed(by: disposeBag)
    }

    // MARK: - Methods

    func configureAsSended(with mission: HomeSendedMission) {
        self.type = .sended
        imageContainerView.backgroundColor = mission.category.backgroundColor
        categoryImageView.image = mission.category.image
        nameTag.updateText(with: mission.assignee)
        dateTag.updateText(with: "~" + mission.dueDate)
        if mission.isOverdue { dateTag.updateTextColor(.gray200) }
        daysLeftLabel.text = mission.daysLeft
        titleLabel.text = mission.title
        updateStatusView(for: mission.status)
    }

    func configureAsReceived(with mission: HomeReceivedMission) {
        self.type = .received
        imageContainerView.backgroundColor = mission.category.backgroundColor
        categoryImageView.image = mission.category.image
        newTag.isHidden = !(mission.isNew ?? false)
        nameTag.updateText(with: mission.assigner)
        dateTag.updateText(with: "~" + mission.dueDate)
        if mission.isOverdue { dateTag.updateTextColor(.gray200) }
        titleLabel.text = mission.title
        statusButton.updateStatus(to: mission.status)
    }

    private func toggleViewOnType() {
        statusButton.isHidden = type == .sended
        statusView.isHidden = type == .received
    }

    private func updateStatusView(for status: MissionStatus) {
        statusLabel.isHidden = status == .assigned
        statusLabel.text = status.text
        statusLabel.textColor = status == .completed ? .red400 : .gray400

        statusImage.image = status == .completed ? .checkRed : .xGray400
        statusImage.isHidden = status == .assigned
    }
}

extension AssignedMissionCell {
    enum MissionType {
        case received
        case sended
    }
}
