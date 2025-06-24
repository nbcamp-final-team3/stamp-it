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
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 24 // 48/2
        $0.backgroundColor = .gray200
        $0.image = UIImage(named: "profileImage1")
    }

    private let nameLabel = UILabel().then {
        $0.font = .pretendard(size: 16, weight: .semibold)
        $0.textColor = .gray800
    }

    private let dateLabel = UILabel().then {
        $0.font = .pretendard(size: 13, weight: .regular)
        $0.textColor = .gray400
    }

    private let optionButton = UIButton().then {
        $0.setImage(UIImage(named: "MoreVert"), for: .normal)
        $0.tintColor = .gray400
    }

    private let infoStack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .leading
    }

    private let hStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 12
        $0.alignment = .center
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
        contentView.addSubview(hStack)
        [profileImageView, infoStack, optionButton].forEach { hStack.addArrangedSubview($0) }
        [nameLabel, dateLabel].forEach { infoStack.addArrangedSubview($0) }

        hStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
        profileImageView.snp.makeConstraints {
            $0.width.height.equalTo(48)
        }
        optionButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
    }

    private func setupShadowAndCorner() {
        backgroundColor = .clear
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 1
        layer.shadowOpacity = 0.08
        layer.masksToBounds = false
    }

    // MARK: - Configure
    func configure(with item: MemberDeleteViewModel.Item) {
        nameLabel.text = item.name
        dateLabel.text = "가입일: 0000년 00월 00일" // 실제 데이터로 교체
        // profileImageView.image = ... // 실제 이미지로 교체
    }
}
