//
//  ProfileImageCell.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/17/25.
//

import UIKit
import SnapKit
import Then

final class ProfileImageCell: UICollectionViewCell {
    static let reuseIdentifier = "ProfileImageCell"
    
    private let imageView = UIImageView().then {
        $0.contentMode = .center
        $0.backgroundColor = .gray25
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        prepareSubview()
        
        setConstraints()
    }
    
    // 셀이 선택되면 셀 스타일을 업데이트
    override var isSelected: Bool {
        didSet {
            updateCell()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func prepareSubview() {
        contentView.addSubview(imageView)
        
        contentView.layer.cornerRadius = 30 // 셀 모양 원형임(60 * 60)
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.gray200.cgColor
    }
    
    private func setConstraints() {
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    /// 컬렉션 뷰 셀 업데이트
    /// - Parameter image: 프로필 이미지
    func configure(with image: UIImage?) {
        imageView.image = image
    }
    
    private func updateCell() {
        if isSelected {
            contentView.layer.borderColor = UIColor.red400.cgColor
            imageView.backgroundColor = .white
        } else {
            contentView.layer.borderColor = UIColor.gray200.cgColor
            imageView.backgroundColor = .gray25
        }
    }
}
