//
//  NoResultsView.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/12/25.
//

import UIKit
import SnapKit
import Then

final class NoResultsView: UIView {
    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "MascotCharacterSadGray")
        $0.contentMode = .scaleAspectFit
    }
    
    private let titleLabel = UILabel().then {
        $0.text = "검색 결과가 없어요"
        $0.font = .pretendard(size: 16, weight: .bold)
        $0.textColor = .gray600
    }
    
    private let descriptionLabel = UILabel().then {
        $0.text = "다른 검색어로 검색해보세요"
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .gray300
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        [imageView, titleLabel, descriptionLabel].forEach {
            addSubview($0)
        }
        
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setConstraints() {
        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(safeAreaLayoutGuide.snp.top).offset(64)
            $0.width.equalTo(80)
            $0.height.equalTo(100)
        }
        
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(imageView.snp.bottom).offset(16)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
    }
}
