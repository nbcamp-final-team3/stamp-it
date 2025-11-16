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

    // MARK: - UI Components
    
    private let stampImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.layer.cornerRadius = StampType.imageSize / 2
        $0.image = UIImage(named: StampType.gray.rawValue)
    }

    private let horizontalLine = DashedLine(direction: .horizontal)
    private let verticalLine = DashedLine(direction: .vertical)

    override func prepareForReuse() {
        super.prepareForReuse()
        configureDashedLine(with: .none)
        stampImageView.image = nil
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
            horizontalLine,
            verticalLine,
            stampImageView,
        ]
            .forEach { addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        stampImageView.snp.makeConstraints {
            $0.size.equalTo(StampType.imageSize)
            $0.top.leading.equalToSuperview()
        }
        
        horizontalLine.snp.makeConstraints {
            $0.height.equalTo(3)
            $0.width.equalToSuperview()
            $0.top.equalToSuperview().offset(StampType.imageSize / 2)
            $0.trailing.equalToSuperview()
        }
        
        verticalLine.snp.makeConstraints {
            $0.height.equalTo(MyPage.StampBoard.height)
            $0.width.equalTo(3)
            $0.leading.equalToSuperview().offset(StampType.imageSize / 2)
            $0.top.equalToSuperview()
        }
    }
    
    // MARK: - Methods
    
    func configure(with appearance: StampCellAppearance) {
        stampImageView.image = UIImage(named: appearance.color.rawValue)
        appearance.isHighlighted ? stopHighlight() : startHighlight()
    }
    
    private func startHighlight() {
        stampImageView.layer.shadowColor = UIColor.yellowGlow.cgColor
        stampImageView.layer.shadowOpacity = 1
        stampImageView.layer.shadowRadius = 9
        stampImageView.layer.shadowOffset = .zero

        guard stampImageView.bounds.width > 0,
              stampImageView.bounds.height > 0 else { return }

        let path = UIBezierPath(
            roundedRect: stampImageView.bounds,
            cornerRadius: stampImageView.layer.cornerRadius
        )
        stampImageView.layer.shadowPath = path.cgPath
    }
    
    private func stopHighlight() {
        let duration: CFTimeInterval = 0.35
        let fadeOut = CABasicAnimation(keyPath: "shadowOpacity")
        fadeOut.fromValue = stampImageView.layer.shadowOpacity
        fadeOut.toValue = 0.0
        fadeOut.duration = duration
        fadeOut.timingFunction = CAMediaTimingFunction(name: .easeOut)

        stampImageView.layer.shadowOpacity = 0.0
        stampImageView.layer.add(fadeOut, forKey: "shadowFadeOut")

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.stampImageView.layer.shadowPath = nil
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
