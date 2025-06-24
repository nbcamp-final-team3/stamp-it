//
//  MemberDeleteCell.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/15/25.
//

import UIKit
import Then
import SnapKit

final class MemberDeleteCell: UICollectionViewCell {
    static let reuseIdentifier = "MemberDeleteCell"

    // MARK: - UI
    private let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 40
        $0.backgroundColor = .gray500
        $0.image = UIImage(named: "profileImage1")
        $0.clipsToBounds = true
    }

    private let nameLabel = UILabel().then {
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray800
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingMiddle
    }

    let exportButton = DefaultButton(type: .export)

    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 8
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupShadowAndCorner()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 셀의 레이아웃이 변경될 때마다 contentView의 cornerRadius에 맞춰 그림자 경로를 업데이트하여 성능 최적화
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
    }

    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(stackView)

        [profileImageView, nameLabel, exportButton]
            .forEach { stackView.addArrangedSubview($0) }

        stackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(8)
            $0.top.bottom.equalToSuperview().inset(16)
        }

        profileImageView.snp.makeConstraints {
            $0.height.equalTo(80)
            $0.width.equalTo(80)
        }

        exportButton.snp.makeConstraints {
            $0.width.greaterThanOrEqualTo(88)
            $0.height.equalTo(36)
        }
    }

    private func setupShadowAndCorner() {
        backgroundColor = .clear
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true

        // 셀 자체에 그림자 적용
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 1
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
    }

    // MARK: - Configure
    
    func configure(with item: MemberDeleteViewModel.Item) {
        nameLabel.text = item.name
    }
}
