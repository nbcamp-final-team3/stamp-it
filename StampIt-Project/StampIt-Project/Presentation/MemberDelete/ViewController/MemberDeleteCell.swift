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
        $0.layer.cornerRadius = 40 // 80x80 원형
        $0.backgroundColor = .gray500 // placeholder color
        $0.image = UIImage(named: "MascotCharacter") // Assets의 mascotCharacter 기본 이미지
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

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup
    private func setupUI() {

        [profileImageView, nameLabel, exportButton]
            .forEach { contentView.addSubview($0) }

        profileImageView.snp.makeConstraints {

            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(80)
        }
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
        exportButton.snp.makeConstraints {
            $0.top.equalTo(nameLabel.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
            $0.width.greaterThanOrEqualTo(88)
            $0.height.equalTo(36)
            $0.bottom.equalToSuperview().inset(12) // 하단 여백 추가
        }
    }

    // MARK: - Configure
    func configure(with member: Member) {
        nameLabel.text = member.nickname
//        profileImageView.image = member. // user속성을 알아야 유저의 프로필 이미지 가져옴
    }
    
    func configure(with item: MemberDeleteViewModel.Item) {
        nameLabel.text = item.name
    }
}
