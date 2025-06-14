//
//  SelectInvitationView.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxRelay

final class SelectInvitationView: UIView {

    // MARK: - Actions

    let didTapOptionCard = PublishRelay<InvitationType>()
    let didTapConfirmButton = PublishRelay<Void>()

    // MARK: - Properties

    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let titleStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 5
    }

    private let titleLabel = UILabel().then {
        let size: CGFloat = 20
        $0.setTextWithLineHeight(text: "그룹 구성하기", lineHeight: size * 1.2)
        $0.font = .pretendard(size: size, weight: .medium)
        $0.textColor = ._000000
    }

    private let descriptionLabel = UILabel().then {
        let size: CGFloat = 14
        $0.setTextWithLineHeight(text: "그룹을 구성할 방식을 선택하세요", lineHeight: size * 1.5)
        $0.font = .pretendard(size: size, weight: .regular)
        $0.textColor = ._4_E_4_E_4_E
    }

    private let optionStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
    }

    private let sendOptionCard = OptionSelectionCard(type: .send)

    private let receiveOptionCard = OptionSelectionCard(type: .receive)

    private let confirmButton = DefaultButton(type: .confirm).then {
        $0.isEnabled = false
    }

    // MARK: - Init

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

    // MARK: - Set Styles

    private func setStyles() {
        backgroundColor = .FFFFFF
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            titleStackView,
            optionStackView,
            confirmButton,
        ].forEach { addSubview($0) }

        [
            titleLabel,
            descriptionLabel,
        ].forEach { titleStackView.addArrangedSubview($0) }

        [
            sendOptionCard,
            receiveOptionCard,
        ].forEach { optionStackView.addArrangedSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        titleStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(50)
            make.directionalHorizontalEdges.equalToSuperview().inset(20)
        }

        optionStackView.snp.makeConstraints { make in
            make.top.equalTo(titleStackView.snp.bottom).offset(30)
            make.directionalHorizontalEdges.equalToSuperview().inset(20)
        }

        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(optionStackView.snp.bottom).offset(30)
            make.directionalHorizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(54)
        }
    }

    // MARK: - Bind

    private func bind() {
        sendOptionCard.rx.controlEvent(.touchUpInside)
            .map { InvitationType.send }
            .bind(to: didTapOptionCard)
            .disposed(by: disposeBag)

        receiveOptionCard.rx.controlEvent(.touchUpInside)
            .map { InvitationType.receive }
            .bind(to: didTapOptionCard)
            .disposed(by: disposeBag)

        confirmButton.rx.tap
            .bind(to: didTapConfirmButton)
            .disposed(by: disposeBag)
    }

    func handleSelectedOption(_ type: InvitationType?) {
        switch type {
        case .send:
            sendOptionCard.isSelected = true
            receiveOptionCard.isSelected = false
        case .receive:
            sendOptionCard.isSelected = false
            receiveOptionCard.isSelected = true
        case nil:
            sendOptionCard.isSelected = false
            receiveOptionCard.isSelected = false
        }
    }

    func setConfirmButton(isEnabled: Bool) {
        confirmButton.isEnabled = isEnabled
    }
}
