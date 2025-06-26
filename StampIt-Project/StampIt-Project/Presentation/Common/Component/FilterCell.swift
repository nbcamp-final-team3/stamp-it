//
//  FilterCell.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/10/25.
//

import UIKit
import SnapKit
import Then

final class FilterCell: UICollectionViewCell {
    static let reuseIdentifier = "FilterCell"

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
    }
    
    private let label = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .semibold)
        $0.textColor = .gray400
        $0.textAlignment = .center
    }
    
    private let stackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 3.5
        $0.isLayoutMarginsRelativeArrangement = true
        // image 있을 때 마진 값
        $0.layoutMargins = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
    }
    
    // 셀이 선택되면 셀 스타일을 업데이트
    override var isSelected: Bool {
        didSet {
            updateCell()
        }
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
        contentView.layer.borderColor = UIColor.gray200.cgColor
    }
    
    private func setConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(20)
        }

        label.snp.makeConstraints {
            $0.height.equalTo(20)
        }
    }
    
    /// 컬렉션 뷰 셀 업데이트
    /// - Parameters:
    ///   - image: 아이콘 이미지
    ///   - title: 타이틀 텍스트
    ///   - titleColor: 타이틀 색깔
    ///   - titleWeight: 타이틀 굵기
    ///   - backgroundColor: 스택 뷰 배경색깔
    func configure(image: UIImage? = nil, title: String? = nil, titleColor: UIColor? = nil, titleWeight: UIFont.Weight? = nil, backgroundColor: UIColor? = nil, isMediumSize: Bool = true) {
        if let image {
            imageView.image = image
            stackView.layoutMargins.left = 8
            stackView.layoutMargins.right = 8
        } else {
            imageView.isHidden = true
            stackView.layoutMargins.left = 12
            stackView.layoutMargins.right = 12
        }

        stackView.layoutMargins.top = isMediumSize ? 6 : 4
        stackView.layoutMargins.bottom = isMediumSize ? 6 : 4

        label.text = title
        if let titleColor {
            label.textColor = titleColor
        }

        if let titleWeight {
            label.font = .pretendard(size: 14, weight: titleWeight)
        }
        
        stackView.backgroundColor = backgroundColor
    }
    
    private func updateCell() {
        if isSelected {
            contentView.layer.borderColor = UIColor.red400.cgColor
            stackView.backgroundColor = .red400
            label.textColor = .white
            if label.text == MissionCategory.chore.title {
                imageView.image = .choreStroke
            }
        } else {
            contentView.layer.borderColor = UIColor.gray200.cgColor
            stackView.backgroundColor = .white
            label.textColor = .gray400
            if label.text == MissionCategory.chore.title {
                imageView.image = .chore
            }
        }
    }
}
