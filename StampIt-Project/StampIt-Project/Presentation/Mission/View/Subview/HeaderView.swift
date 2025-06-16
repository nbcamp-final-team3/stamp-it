//
//  HeaderView.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/13/25.
//

import UIKit
import SnapKit
import Then

final class HeaderView: UIView {
    private let label = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .semibold)
        $0.textColor = .gray800
        $0.backgroundColor = .white
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(label)
        
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setConstraints() {
        label.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    /// 헤더 뷰 텍스트 업데이트
    /// - Parameter text: '\(text)' 검색 결과입니다
    func configure(with text: String) {
        label.text = "'\(text)' 검색 결과입니다"
    }
}
