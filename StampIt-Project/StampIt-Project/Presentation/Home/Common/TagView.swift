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
    
    override var intrinsicContentSize: CGSize {
        let labelSize = label.intrinsicContentSize
        let width = labelSize.width + 8 * 2
        let height = labelSize.height + verticalInset * 2
        return CGSize(width: width, height: height)
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
        case filledLightSmall
        case filledLightMedium
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
        default: nil
        }
    }

    private var textColor: UIColor {
        switch type {
        case .filledLightSmall: ._000000
        case .filledLightMedium: .gray800
        case .filledBold: .gray400
        case .outlined: .yellow400
        }
    }

    private var font: UIFont {
        switch type {
        case .filledLightSmall, .filledLightMedium: .pretendard(size: 12, weight: .regular)
        case .filledBold, .outlined: .pretendard(size: 12, weight: .semibold)
        }
    }

    private var baseBackgroundColor: UIColor? {
        switch type {
        case .filledLightSmall, .filledBold: .gray25
        case .filledLightMedium: .gray50
        case .outlined: .FFFFFF
        }
    }

    private var labelHeight: CGFloat {
        switch type {
        case .filledLightSmall, .filledLightMedium: 18
        case .filledBold, .outlined: 14
        }
    }

    private var verticalInset: CGFloat {
        switch type {
        case .filledLightSmall: 1
        case .filledLightMedium: 3
        case .filledBold, .outlined: 4
        }
    }
}
