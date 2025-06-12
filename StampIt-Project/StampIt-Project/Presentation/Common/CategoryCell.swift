//
//  CategoryCell.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/10/25.
//

import UIKit
import SnapKit
import Then

final class CategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryCell"
    
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let label = UILabel().then {
        $0.font = .systemFont(ofSize: 10, weight: .medium)
        $0.textAlignment = .center
    }
    
    private let stackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 2
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        prepareSubviews()
        
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func prepareSubviews() {
        contentView.addSubview(stackView)
        
        [imageView, label].forEach {
            stackView.addArrangedSubview($0)
        }
        
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
    }
    
    private func setConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
    }
    
    /// 컬렉션 뷰 셀 업데이트
    /// - Parameters:
    ///   - image: 아이콘 이미지
    ///   - title: 타이틀 텍스트
    ///   - titleColor: 타이틀 색깔
    ///   - backgroundColor: 스택 뷰 배경색깔
    func configure(image: UIImage? = nil, title: String? = nil, titleColor: UIColor? = nil, titleWeight: UIFont.Weight? = nil, backgroundColor: UIColor? = nil) {
        if let image {
            imageView.image = image
        } else {
            imageView.isHidden = true
        }
        
        label.text = title
        label.textColor = titleColor
        
        if let titleWeight {
            label.font = .systemFont(ofSize: 10, weight: titleWeight)
        }
        
        stackView.backgroundColor = backgroundColor
    }
}
