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
        $0.image = UIImage(systemName: "star.fill")
        $0.tintColor = .red200
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        [label, favoriteImageView].forEach { addSubview($0) }
        
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
            $0.trailing.equalToSuperview().inset(16)
        }
    }
    
    /// 테이블 뷰 셀 업데이트
    /// - Parameter text: 미션 타이틀(예: 방 청소하기)
    func configure(with text: String, isFavorite: Bool) {
        label.text = text
        
        if isFavorite {
            favoriteImageView.isHidden = false
        } else {
            favoriteImageView.isHidden = true
        }
    }
}
