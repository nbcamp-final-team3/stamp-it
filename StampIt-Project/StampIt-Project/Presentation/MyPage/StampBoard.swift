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
    
    private let lable = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .neutralGray500
        
        $0.text = "stamp"
    }
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            lable,
        ]
            .forEach { addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        lable.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}
