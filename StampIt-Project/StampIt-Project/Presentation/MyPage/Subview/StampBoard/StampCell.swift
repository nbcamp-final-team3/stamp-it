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
        $0.layer.cornerRadius = Stamp.Board.imageSize / 2
        $0.image = UIImage(named: Stamp.stampGray.rawValue)
    }
    
    private let horizontalLine = DashedLine(direction: .horizontal)
    private let verticalLine = DashedLine(direction: .vertical)
    
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
            $0.size.equalTo(Stamp.Board.imageSize)
            $0.top.leading.equalToSuperview()
        }
        
        horizontalLine.snp.makeConstraints {
            $0.width.equalTo(Stamp.Board.imageSize)
            $0.leading.top.equalToSuperview().offset(Stamp.Board.imageSize / 2)
        }
        
        verticalLine.snp.makeConstraints {
            $0.height.equalTo(Stamp.Board.imageSize)
            $0.leading.top.equalToSuperview().offset(Stamp.Board.imageSize / 2)
        }
    }
    
    // MARK: - Methods
    
    func configureStamp(with type: Sticker) {
        stampImageView.image = UIImage(named: type.imageType.rawValue)
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
