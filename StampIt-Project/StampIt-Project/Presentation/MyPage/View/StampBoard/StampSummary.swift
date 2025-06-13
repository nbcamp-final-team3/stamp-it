//
//  StampSummary.swift
//  StampIt-Project
//
//  Created by kingj on 6/10/25.
//

import UIKit
import Then
import SnapKit

final class StampSummary: UIView {
    
    // MARK: - UI Components
    
    /// Vertical Stack View - 내가 모은 스탬프
    private let stampVStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = MyPage.Stamp.vStackSpacing
    }
    
    /// 내가 모은 스탬프
    private let collectedStampTitle = UILabel().then {
        $0.text = MyPage.Stamp.collected
        $0.font = .pretendard(size: MyPage.Stamp.fontSizeMedium, weight: .regular)
        $0.textColor = .gray800
    }
    
    /// 내가 모은 스탬프 - 현재 개수
    private let currentStampLabel = UILabel().then {
        $0.text = "0"
        $0.font = .pretendard(size: MyPage.Stamp.fontSizeMedium, weight: .bold)
        $0.textColor = .gray800
    }
    
    /// 내가 모은 스탬프 - /
    private let slashLabel = UILabel().then {
        $0.text = MyPage.Stamp.slash
        $0.font = .pretendard(size: MyPage.Stamp.fontSizeMedium, weight: .regular)
        $0.textColor = .gray800
    }

    /// 내가 모은 스탬프 - 30
    private let totalStampLabel = UILabel().then {
        $0.text = MyPage.Stamp.totalStamp
        $0.font = .pretendard(size: MyPage.Stamp.fontSizeSmall, weight: .regular)
        $0.textColor = .gray800
    }
    
    /// Horizontal Stack View - 현재 개수 / 30
    private let stampHStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
    }
    
    /// Vertical Stack View - 완성한 스탬프 판
    private let boardVStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = MyPage.Stamp.vStackSpacing
    }
    
    /// 완성한 스탬프 판
    private let completedBoardTitle = UILabel().then {
        $0.text = MyPage.Stamp.completed
        $0.font = .pretendard(size: MyPage.Stamp.fontSizeMedium, weight: .regular)
        $0.textColor = .gray800
    }
    
    /// 완성한 스탬프 판 - N개
    private let totalBoardLabel = UILabel().then {
        $0.text = "0\(MyPage.Stamp.unit)"
        $0.font = .pretendard(size: MyPage.Stamp.fontSizeMedium, weight: .bold)
        $0.textColor = .gray800
    }
    
    /// Horizontal Stack View - 내가 모은 스탬프 | 완성한 스탬프 판
    private let hStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .fillEqually
    }
    
    private let divider = UIView().then {
        $0.backgroundColor = .gray50
    }
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setStyle()
        setHierarchy()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout Subviews

    override func layoutSubviews() {
        setShadow()
    }
    
    private func setShadow() {
        let insetRect = bounds.insetBy(dx: 1, dy: 1) // 테두리 부분만 그림자 주기
        let path = UIBezierPath(roundedRect: insetRect, cornerRadius: layer.cornerRadius)
        layer.shadowPath = path.cgPath
        layer.cornerRadius = 12
        layer.shadowColor = UIColor._000000.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = .zero
    }

    // MARK: - Style Helper
    
    private func setStyle() {
        backgroundColor = .white
        layer.masksToBounds = false
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            hStackView,
            divider,
        ]
            .forEach { addSubview($0) }
        
        [
            stampVStackView,
            boardVStackView
        ]
            .forEach { hStackView.addArrangedSubview($0) }
        
        [
            collectedStampTitle,
            stampHStackView,
        ]
            .forEach { stampVStackView.addArrangedSubview($0) }
        
        [
            currentStampLabel,
            slashLabel,
            totalStampLabel,
        ]
            .forEach { stampHStackView.addArrangedSubview($0) }
        
        [
            completedBoardTitle,
            totalBoardLabel,
        ]
            .forEach { boardVStackView.addArrangedSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        hStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
            $0.height.equalTo(44)
        }
        
        divider.snp.makeConstraints {
            $0.directionalVerticalEdges.equalToSuperview().inset(12)
            $0.width.equalTo(1)
            $0.center.equalToSuperview()
        }
    }
}
