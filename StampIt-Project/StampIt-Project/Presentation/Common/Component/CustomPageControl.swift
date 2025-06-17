//
//  CustomPageControl.swift
//  StampIt-Project
//
//  Created by iOS study on 6/15/25.
//

import UIKit
import SnapKit

final class CustomPageControl: UIView {
    
    // MARK: - Properties
    private var numberOfPages: Int = 0
    private var currentPage: Int = 0 {
        didSet {
            updateIndicators()
        }
    }
    
    private var indicators: [UIView] = []
    private let stackView = UIStackView()
    
    // MARK: - Constants
    private let indicatorSize: CGSize = CGSize(width: 8, height: 8)
    private let activeIndicatorSize: CGSize = CGSize(width: 30, height: 8)
    private let indicatorSpacing: CGFloat = 8
    
    // MARK: - Colors
    private let activeColor = UIColor(named: "red400")
    private let inactiveColor = UIColor(named: "red200")
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStackView()
    }
    
    // MARK: - Setup
    private func setupStackView() {
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = indicatorSpacing
        
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    func configure(numberOfPages: Int, currentPage: Int = 0) {
        self.numberOfPages = numberOfPages
        self.currentPage = currentPage
        createIndicators()
        updateIndicators()
    }
    
    func setCurrentPage(_ page: Int, animated: Bool = true) {
        guard page >= 0 && page < numberOfPages else { return }
        self.currentPage = page
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.updateIndicators()
                self.layoutIfNeeded()
            }
        } else {
            updateIndicators()
        }
    }
    
    // MARK: - Private Methods
    private func createIndicators() {
        // 기존 인디케이터 제거
        indicators.forEach { $0.removeFromSuperview() }
        indicators.removeAll()
        
        // 새 인디케이터 생성
        for _ in 0..<numberOfPages {
            let indicator = UIView()
            indicator.layer.cornerRadius = indicatorSize.height / 2
            indicator.backgroundColor = inactiveColor
            indicators.append(indicator)
            stackView.addArrangedSubview(indicator)
        }
    }
    
    private func updateIndicators() {
        for (index, indicator) in indicators.enumerated() {
            let isActive = index == currentPage
            let size = isActive ? activeIndicatorSize : indicatorSize
            let color = isActive ? activeColor : inactiveColor
            
            // 크기 업데이트
            indicator.snp.remakeConstraints {
                $0.width.equalTo(size.width)
                $0.height.equalTo(size.height)
            }
            
            // 색상 및 모서리 업데이트
            indicator.backgroundColor = color
            indicator.layer.cornerRadius = size.height / 2
        }
    }
}
