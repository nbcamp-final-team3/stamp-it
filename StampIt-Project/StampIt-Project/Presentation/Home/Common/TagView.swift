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

    // MARK: - Properties

    private var type: TagType

    // MARK: - UI Components

    private lazy var label = UILabel().then {
        $0.font = font
        $0.textColor = textColor
        $0.textAlignment = .center
        $0.baselineAdjustment = .alignCenters
    }

    // MARK: - Init

    init(type: TagType) {
        self.type = type
        super.init(frame: .zero)
        setStyles()
        setHierarchy()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Set Styles

    private func setStyles() {
        backgroundColor = baseBackgroundColor
        layer.cornerRadius = (labelHeight + verticalInset * 2) / 2
        layer.borderColor = borderColor
        layer.borderWidth = borderWidth
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        addSubview(label)
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        label.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(verticalInset)
            make.directionalHorizontalEdges.equalToSuperview().inset(8)
            make.height.equalTo(labelHeight)
        }
    }

    // MARK: - Methods

    func updateText(with text: String) {
        label.text = text
    }

    func updateTextColor(_ color: UIColor) {
        label.textColor = color
    }
}

extension TagView {
    enum TagType {
        case filledLight
        case filledBold
        case outlined
    }

    private var borderWidth: CGFloat {
        switch type {
        case .outlined: 1
        default: 0
        }
    }

    private var borderColor: CGColor? {
        switch type {
        case .outlined: UIColor.yellow400.cgColor
        case .filledLight, .filledBold: nil
        }
    }

    private var textColor: UIColor {
        switch type {
        case .filledLight: ._000000
        case .filledBold: .gray400
        case .outlined: .yellow400
        }
    }

    private var font: UIFont {
        switch type {
        case .filledLight: .pretendard(size: 12, weight: .regular)
        case .filledBold, .outlined: .pretendard(size: 12, weight: .semibold)
        }
    }

    private var baseBackgroundColor: UIColor? {
        switch type {
        case .filledLight, .filledBold: .gray25
        case .outlined: .FFFFFF
        }
    }

    private var labelHeight: CGFloat {
        switch type {
        case .filledLight: 18
        case .filledBold, .outlined: 14
        }
    }

    private var verticalInset: CGFloat {
        switch type {
        case .filledLight: 1
        case .filledBold, .outlined: 4
        }
    }
}
