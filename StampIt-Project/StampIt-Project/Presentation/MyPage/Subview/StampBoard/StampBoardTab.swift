//
//  StampBoard.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import UIKit
import Then
import SnapKit

final class StampBoardTab: UIView {

    // MARK: - UI Components
    
    private let stampSummary = StampSummary()
    private let stampBoard = StampBoard()
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setter & Getter
    
    func getStampBoardView() -> UICollectionView {
        stampBoard.getCollectionView()
    }
    
    func setCollectionViewDataSource(
        _ dataSource: UICollectionViewDiffableDataSource<StampBoardSection, StampBoardItem>
    ) {
        stampBoard.setDataSource(dataSource)
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            stampSummary,
            stampBoard
        ]
            .forEach { addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        stampSummary.snp.makeConstraints {
            $0.top.equalToSuperview().offset(30)
            $0.directionalHorizontalEdges.equalToSuperview().inset(16)
        }
        
        stampBoard.snp.makeConstraints {
            $0.top.equalTo(stampSummary.snp.bottom).offset(34)
            $0.leading.equalToSuperview().inset(36)
            $0.trailing.equalToSuperview().inset(Stamp.Board.imageSize / 3)
            $0.bottom.equalToSuperview()
        }
    }
}
