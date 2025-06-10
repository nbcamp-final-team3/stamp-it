//
//  StampBoard.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import UIKit
import Then
import SnapKit

final class StampBoard: UIView {
    
    // MARK: - UI Components
    
    private let stampSummary = StampSummary()
    
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
    
    // MARK: - Style Helper
    
    private func setStyle() {
        
        // TODO: stampSummary Shadow
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            stampSummary,
        ]
            .forEach { addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        stampSummary.snp.makeConstraints {
            $0.top.equalToSuperview().offset(30)
            $0.directionalHorizontalEdges.equalToSuperview().inset(16)
        }
    }
}
