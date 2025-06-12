//
//  DashedLine.swift
//  StampIt-Project
//
//  Created by kingj on 6/10/25.
//

import UIKit

enum DashdLineDirection {
    case horizontal
    case vertical
}

final class DashedLine: UIView {
    
    // MARK: - Properties
    
    private let direction: DashdLineDirection
    
    // MARK: - UI Components
    
    private let lineLayer = CAShapeLayer()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(direction: DashdLineDirection) {
        self.direction = direction
        super.init(frame: .zero)
        setHierarchy()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        layer.addSublayer(lineLayer)
    }
    
    // MARK: - Layout Subviews
    
    /// 내부요소를 재 배치 하기 위한 메서드
    ///
    /// DashedLine View의 크기가 정해졌을때, 크기에 맞춰 내부 요소들을 재 배치하기 위한 메서드이다.
    /// init 시점에서는 bounds 의 크기가 0.0 일 가능성이 높다.
    /// 따라서, Auto Layout 완료 후 불리는 `layoutSubviews()` 에서 크기를 정의 해준다.
    override func layoutSubviews() {
        super.layoutSubviews()
        configureDashedLine()
    }

    // MARK: - Configuration
    
    private func configureDashedLine() {
        let path = UIBezierPath() // 선의 시작점과 끝점을 정의
        
        switch direction {
        case .horizontal:
            path.move(to: CGPoint(x: 0, y: 0)) // 시작점
            path.addLine(to: CGPoint(x: bounds.width, y: 0)) // 끝점
        case .vertical:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: bounds.height))
        }
        
        lineLayer.path = path.cgPath
        lineLayer.strokeColor = UIColor.neutralGray300.withAlphaComponent(0.6).cgColor
        lineLayer.lineCap = .round
        lineLayer.lineWidth = 2.0
        lineLayer.lineDashPattern = [2, 4]
    }
}
