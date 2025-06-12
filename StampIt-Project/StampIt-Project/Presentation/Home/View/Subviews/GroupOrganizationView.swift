//
//  GroupOrganizationView.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class GroupOrganizationView: UIView {

    // MARK: - Actions

    let didTapGroupOrganizationButton = PublishRelay<Void>()

    // MARK: - Properties

    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let containerView = UIView().then {
        $0.backgroundColor = .red50
        $0.layer.cornerRadius = 20
        $0.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    private let mascotImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.image = .mascotRed
    }

    private let contentLabel = UILabel().then {
        $0.setTextWithLineHeight(
            text: "현재 그룹 구성원이 없어요!\n미션을 클리어할 수 있도록 그룹을 구성해보세요",
            lineHeight: 21
        )
        $0.font = .pretendard(size: 14, weight: .medium)
        $0.textColor = ._1_E_1_E_1_E
        $0.numberOfLines = 2
        $0.textAlignment = .center
    }

    private let groupButton = DefaultButton(type: .groupOrganization)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setConstraints()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        addSubview(containerView)

        [
            mascotImageView,
            contentLabel,
            groupButton,
        ].forEach { containerView.addSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        containerView.snp.makeConstraints { make in
            make.top.directionalHorizontalEdges.equalToSuperview().inset(16)
        }

        mascotImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(28)
            make.centerX.equalToSuperview()
            make.width.equalTo(50)
            make.height.equalTo(mascotImageView.snp.width).multipliedBy(1.2)
        }

        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(mascotImageView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }

        groupButton.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(36)
            make.bottom.equalToSuperview().inset(28)
        }
    }

    // MARK: - Bind

    private func bind() {
        groupButton.rx.tap
            .bind(to: didTapGroupOrganizationButton)
            .disposed(by: disposeBag)
    }
}
