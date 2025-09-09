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
    }
    
    private let horizontalLine = DashedLine(direction: .horizontal)
    private let verticalLine = DashedLine(direction: .vertical)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        configureDashedLine(with: .none)
        removeBlur(from: stampImageView)
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
    
    func configureStamp(with type: StampBoardStamp) {
        stampImageView.image = UIImage(named: type.type.rawValue)
        
        if type.shouldBlur {
            applyBlur(to: stampImageView)

            /// 3초 후 블러 제거
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                guard let self else { return }
                self.removeBlur(from: self.stampImageView)
            }
        } else {
            removeBlur(from: stampImageView)
        }
    }
    
    private func applyBlur(to view: UIView) {
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
    }
    
    private func removeBlur(from view: UIView) {
        view.layer.shadowOpacity = 0.0
        view.layer.shadowPath = nil
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
