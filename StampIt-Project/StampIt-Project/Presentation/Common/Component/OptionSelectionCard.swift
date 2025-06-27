//
//  OptionSelectionCard.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxRelay

final class OptionSelectionCard: UIControl {

    // MARK: - Properties

    override var isSelected: Bool {
        didSet {
            setStyles()
        }
    }

    // MARK: - UIComponent
    
    //옵션 카드 자체적으로 타입을 만들엇 히든 처리
    private let labelStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 2
        $0.isUserInteractionEnabled = false
    }

    private let titleLabel = UILabel().then {
        let size: CGFloat = 16
        $0.setTextWithLineHeight(text: nil, lineHeight: size * 1.2)
        $0.font = .pretendard(size: size, weight: .semibold)
        $0.textColor = ._000000
    }

    private let subtitleLabel = UILabel().then {
        let size: CGFloat = 14
        $0.setTextWithLineHeight(text: nil, lineHeight: size * 1.5)
        $0.font = .pretendard(size: size, weight: .medium)
        $0.textColor = ._777777
    }

    // MARK: - Init
    // 재사용 가능하도록 init은 아무것도 안받고 configure 메서드 만들어서 타이틀 / 서브 타이틀 받게끔
    init() {
        super.init(frame: .zero)
        setStyles()
        setHierarchy()
        setConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure
    func configure(title: String, subtitle: String? = nil) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        
        // 제약조건 업데이트
        updateCardConstraints()
    }
    
    // MARK: - Update Constraints
    private func updateCardConstraints() {
        // 기존 제약조건 제거 후 새로운 제약조건 설정
        labelStackView.snp.removeConstraints()
        labelStackView.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview().inset(16)

            // subtitle이 nil일 때 더 큰 vertical inset 설정
            if subtitleLabel.isHidden {
                $0.verticalEdges.equalToSuperview().inset(20)
            } else {
                $0.verticalEdges.equalToSuperview().inset(12)
            }
        }
    }

    // MARK: - Set Styles

    private func setStyles() {
        backgroundColor = isSelected ? .red50 : .FFFFFF
        layer.borderColor = isSelected ? UIColor.red400.cgColor : UIColor.gray50.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 12
    }

    // MARK: - Set Styles

    private func setHierarchy() {
        [
            labelStackView
        ].forEach { addSubview($0) }

        [
            titleLabel,
            subtitleLabel,
        ].forEach { labelStackView.addArrangedSubview($0) }
    }

    // MARK: - Set Styles

    private func setConstraints() {
        labelStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(12)
            make.directionalHorizontalEdges.equalToSuperview().inset(16)
        }
    }
}
