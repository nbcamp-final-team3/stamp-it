//
//  StampCell.swift
//  StampIt-Project
//
//  Created by kingj on 6/10/25.
//

import UIKit
import Then
import SnapKit

final class StampCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    static let identifier = "StampCell"

    // MARK: - UI Components
    
    private let stampImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = StickerType.imageSize / 2
        $0.image = UIImage(named: StickerType.stampGray.rawValue)
        $0.layer.masksToBounds = false
    }
    
    private let horizontalLine = DashedLine(direction: .horizontal)
    private let verticalLine = DashedLine(direction: .vertical)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        configureDashedLine(with: .none)
        stampImageView.image = nil
        stampImageView.layer.shadowOpacity = 0
        stampImageView.layer.shadowPath = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        applyBlur(withAnimationTo: stampImageView)
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
    
    // MARK: - Style Helper
    
    private func setStyle() {
        contentView.layer.masksToBounds = false
        stampImageView.layer.masksToBounds = false
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            horizontalLine,
            verticalLine,
            stampImageView,
        ]
            .forEach { addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        stampImageView.snp.makeConstraints {
            $0.size.equalTo(StickerType.imageSize)
            $0.top.leading.equalToSuperview()
        }
        
        horizontalLine.snp.makeConstraints {
            $0.height.equalTo(3)
            $0.width.equalToSuperview()
            $0.top.equalToSuperview().offset(StickerType.imageSize / 2)
            $0.trailing.equalToSuperview()
        }
        
        verticalLine.snp.makeConstraints {
            $0.height.equalTo(MyPage.StampBoard.height)
            $0.width.equalTo(3)
            $0.leading.equalToSuperview().offset(StickerType.imageSize / 2)
            $0.top.equalToSuperview()
        }
    }
    
    // MARK: - Methods
    
    func configureStamp(with type: StickerUI) {
        stampImageView.image = UIImage(named: type.type.rawValue)
    }
    
    /// 새로운 스티커 생성시 애니메이션 추가
    func applyBlur(withAnimationTo view: UIView) {
        view.layer.shadowColor = UIColor.yellowGlow.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 9
        view.layer.shadowOffset = .zero
        
        guard view.bounds.width > 0, view.bounds.height > 0 else { return }
        
        let path = UIBezierPath(
            roundedRect: view.bounds,
            cornerRadius: view.layer.cornerRadius
        )
        view.layer.shadowPath = path.cgPath
        
        // 3초 뒤 자연스럽게 사라지는 fade-out 애니메이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let fadeOut = CABasicAnimation(keyPath: "shadowOpacity")
            fadeOut.fromValue = 1.0
            fadeOut.toValue = 0.0
            fadeOut.duration = 0.6
            fadeOut.timingFunction = CAMediaTimingFunction(name: .easeOut)
            fadeOut.fillMode = .forwards
            fadeOut.isRemovedOnCompletion = false

            view.layer.add(fadeOut, forKey: "fadeOutGlow")

            // 최종 opacity 값도 0으로 설정해둬야 실제로 사라짐
            view.layer.shadowOpacity = 0.0
        }
    }
    
    func configureDashedLine(with type: StampCellType) {
        switch type {
        case .horizontal:
            horizontalLine.isHidden = false
            verticalLine.isHidden = true
        case .vertical:
            horizontalLine.isHidden = true
            verticalLine.isHidden = false
        case .both:
            horizontalLine.isHidden = false
            verticalLine.isHidden = false
        case .none:
            horizontalLine.isHidden = true
            verticalLine.isHidden = true
        }
    }
}
