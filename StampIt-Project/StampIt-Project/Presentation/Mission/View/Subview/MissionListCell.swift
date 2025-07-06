//
//  MissionListCell.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/5/25.
//

import UIKit
import SnapKit
import Then

final class MissionListCell: UITableViewCell {
    static let reuseIdentifier = "MissionListCell"
    
    private let label = UILabel().then {
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray800
        $0.numberOfLines = 0
    }
    
    private let favoriteImageView = UIImageView().then {
        $0.image = UIImage(named: "bookmarkRed")
    }
    
    private let recommendationLabel = TagView(type: .filledBold)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        [label, favoriteImageView, recommendationLabel].forEach { addSubview($0) }
        
        setConstraints()
        
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setConstraints() {
        label.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(favoriteImageView).inset(8)
        }
        
        favoriteImageView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(32)
        }
        
        recommendationLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(18)
            $0.height.equalTo(20)
            $0.width.greaterThanOrEqualTo(40)
        }
    }
    
    /// 테이블 뷰 셀 업데이트
    /// - Parameters:
    ///   - text: 미션 타이틀(예: 방 청소하기)
    ///   - isFavorite: 즐겨찾기 여부
    ///   - isRecommended: 추천 미션 여부
    func configure(with text: String, isFavorite: Bool, isRecommended: Bool) {
        label.text = text
        
        if isFavorite, isRecommended { // 둘다 true면 즐겨찾기만 표시함
            favoriteImageView.isHidden = false
            recommendationLabel.isHidden = true
        } else {
            favoriteImageView.isHidden = !isFavorite
            recommendationLabel.isHidden = !isRecommended
            recommendationLabel.updateText(with: isRecommended ? "추천" : "")
        }
    }
}
