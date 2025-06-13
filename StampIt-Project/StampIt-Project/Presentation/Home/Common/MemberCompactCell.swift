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
    
    static let identifier = "MemberCompactCell"
    var type: CellType = .normal {
        didSet {
            setStyles()
            updateNameLabelConstraints()
        }
    }

    override var isSelected: Bool {
        didSet {
            setStylesIfSelectedForNormalType()
        }
    }

    // MARK: - UI Components

    private let imageContainerView = UIView().then {
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 60 / 2
        $0.clipsToBounds = true
    }

    private let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let rankBadgeImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }
    
    private let nameLabel = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textAlignment = .center
    }
    
    private let stickerCountLabel = UILabel().then {
        $0.font = .pretendard(size: 12, weight: .regular)
        $0.textColor = .gray300
        $0.textAlignment = .center
    }

    // MARK: - Init

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
        rankBadgeImageView.isHidden = type != .rank
        stickerCountLabel.isHidden = type != .rank
        imageContainerView.layer.borderWidth = borderWidth
        imageContainerView.layer.borderColor = borderColor
        imageContainerView.layer.opacity = opacity
        nameLabel.textColor = nameTextColor
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            imageContainerView,
            rankBadgeImageView,
            nameLabel,
            stickerCountLabel,
        ].forEach { addSubview($0) }

        [
            profileImageView
        ].forEach { imageContainerView.addSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        imageContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(60)
        }

        profileImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }

        rankBadgeImageView.snp.makeConstraints { make in
            make.bottom.equalTo(imageContainerView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.size.equalTo(16)
        }

        nameLabel.snp.makeConstraints { make in
            let offset = type == .rank ? 8 : 4
            make.top.equalTo(imageContainerView.snp.bottom).offset(offset)
            make.directionalHorizontalEdges.equalToSuperview()
            make.height.equalTo(21)
        }

        stickerCountLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom)
            make.directionalHorizontalEdges.equalToSuperview()
            make.height.equalTo(18)
        }
    }

    private func updateNameLabelConstraints() {
        nameLabel.snp.updateConstraints { make in
            let offset = type == .rank ? 8 : 4
            make.top.equalTo(imageContainerView.snp.bottom).offset(offset)
        }
    }

    // MARK: - Methods

    func configureCell(with member: HomeMember, type: CellType) {
        self.type = type
        // TODO: member에 저장된 이미지로 변경하기
        profileImageView.image = .mascotRed
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

    private func setStylesIfSelectedForNormalType() {
        guard type == .normal else { return }
        imageContainerView.layer.borderColor = borderColor
        imageContainerView.layer.borderWidth = borderWidth
        imageContainerView.layer.opacity = opacity
        nameLabel.textColor = nameTextColor
    }
}

extension MemberCompactCell {
    enum CellType {
        case rank
        case normal
    }

    var borderColor: CGColor {
        switch type {
        case .rank: UIColor.gray200.cgColor
        case .normal: isSelected ? UIColor.red400.cgColor : UIColor.gray200.cgColor
        }
    }

    var borderWidth: CGFloat {
        switch type {
        case .rank: 1
        case .normal: isSelected ? 2 : 1
        }
    }

    var opacity: Float {
        switch type {
        case .rank: 1
        case .normal: isSelected ? 1 : 0.5
        }
    }

    var nameTextColor: UIColor {
        switch type {
        case .rank: ._000000
        case .normal: isSelected ? ._000000 : .gray400
        }
    }
}
