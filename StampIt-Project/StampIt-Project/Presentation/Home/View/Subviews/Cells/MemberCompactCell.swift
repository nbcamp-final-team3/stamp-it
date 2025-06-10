//
//  MemberCompactCell.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/10/25.
//

import UIKit
import SnapKit
import Then
import Kingfisher

final class MemberCompactCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    let identifier = "MemberCompactCell"

    // MARK: - UI Components
    
    private let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .clear
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.gray200.cgColor
        $0.layer.cornerRadius = 60 / 2
        $0.clipsToBounds = true
    }
    
    private let rankBadgeImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }
    
    private let nameLabel = UILabel().then {
        $0.setTextWithLineHeight(text: nil, lineHeight: 14 * 1.5)
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = ._000000
        $0.textAlignment = .center
    }
    
    private let stickerCountLabel = UILabel().then {
        $0.setTextWithLineHeight(text: nil, lineHeight: 12 * 1.5)
        $0.font = .pretendard(size: 12, weight: .regular)
        $0.textColor = .gray300
        $0.textAlignment = .center
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            profileImageView,
            rankBadgeImageView,
            nameLabel,
            stickerCountLabel,
        ].forEach { addSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        profileImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(60)
        }

        rankBadgeImageView.snp.makeConstraints { make in
            make.bottom.equalTo(profileImageView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.size.equalTo(16)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(8)
            make.directionalHorizontalEdges.equalToSuperview()
        }

        stickerCountLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom)
            make.directionalHorizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Methods

    func configureCell(with member: HomeMember) {
        profileImageView.kf.setImage(with: URL(string: member.profileImageURL!))
        nameLabel.text = member.nickname
        stickerCountLabel.text = "\(member.stickerCount)개"
        handleRank(rank: member.rank)
    }

    private func handleRank(rank: Int) {
        if 1...3 ~= rank {
            rankBadgeImageView.image = rank == 1 ? .first : rank == 2 ? .second : .third
        } else {
            rankBadgeImageView.isHidden = true
        }
    }
}
