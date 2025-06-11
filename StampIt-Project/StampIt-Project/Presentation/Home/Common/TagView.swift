//
//  TagView.swift
//  StampIt-Project
//
//  Created by daeun on 6/11/25.
//

import UIKit
import SnapKit
import Then

final class TagView: UIView {

    // MARK: - UI Components

    private var label = UILabel().then {
        $0.font = .pretendard(size: 12, weight: .regular)
        $0.textColor = ._000000
        $0.textAlignment = .center
        $0.baselineAdjustment = .alignCenters
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Set Styles

    private func setStyles() {
        backgroundColor = .gray50
        layer.cornerRadius = 10
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        addSubview(label)
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        label.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(1)
            make.directionalHorizontalEdges.equalToSuperview().inset(8)
            make.height.equalTo(18)
        }
    }

    // MARK: - Methods

    func configure(with text: String) {
        label.text = text
    }
}
