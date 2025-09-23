//
//  PlaceholderCell.swift
//  StampIt-Project
//
//  Created by daeun on 6/12/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class PlaceholderCell: UICollectionViewCell {

    let didTapButton = PublishRelay<Void>()
    let isSelectedButton = BehaviorRelay<Bool?>(value: nil)
    var disposeBag = DisposeBag()

    // MARK: - Properties

    static let identifier = "PlaceholderCell"

    // MARK: - UI Components

    private let contentStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
        $0.alignment = .center
    }

    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = ._000000
    }

    private let button = UIButton().then {
        var config = UIButton.Configuration.filled()

        // color
        config.baseBackgroundColor = .red50
        config.baseForegroundColor = .red400

        $0.configuration = config

        $0.configurationUpdateHandler = { button in
            var config = button.configuration
            if button.isSelected {
                config?.baseBackgroundColor = .clear
            } else {
                config?.baseBackgroundColor = .red50
            }
            button.configuration = config
        }
    }

    // MARK: - Life Cycles

    override init(frame: CGRect) {
        super.init(frame: frame)
        setStyles()
        setHierarchy()
        setConstraints()
        bindButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        bindButton()
    }

    private func bindButton() {
        button.rx.tap
            .bind(to: didTapButton)
            .disposed(by: disposeBag)

        isSelectedButton
            .compactMap { $0 }
            .bind(to: button.rx.isSelected)
            .disposed(by: disposeBag)
    }

    // MARK: - Set Styles

    private func setStyles() {
        contentView.backgroundColor = .FFFFFF
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray50.cgColor
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            contentStackView,
        ].forEach { contentView.addSubview($0) }

        [
            titleLabel,
            button,
        ].forEach { contentStackView.addArrangedSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        contentStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(21)
        }
    }

    // MARK: - Methods

    func configure(with title: String, buttonTitle: String? = nil) {
        titleLabel.text = title

        if let buttonTitle {
            button.isHidden = false
            setAttributedButton(title: buttonTitle)
        } else {
            button.isHidden = true
        }
    }

    private func setAttributedButton(title: String) {
        guard var config = button.configuration else { return }

        let attributed = AttributedString(title)
        var container = AttributeContainer()
        container.font = UIFont.pretendard(size: 14, weight: .semibold)
        let styled = attributed.settingAttributes(container)
        config.attributedTitle = styled

        config.contentInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)

        button.configuration = config
    }
}
