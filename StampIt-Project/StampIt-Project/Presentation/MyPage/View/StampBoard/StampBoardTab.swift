//
//  StampBoard.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxRelay

final class StampBoardTab: UIView {
    
    // MARK: - Properties
    
    var stickerBoardDataSource: UICollectionViewDiffableDataSource<StampBoardSection, StampBoardItem>!
    let stickerSummary = BehaviorRelay<(collectedSticker: Int, completedBoard: Int)>(value: (.zero, .zero))
    let disposeBag = DisposeBag()

    // MARK: - UI Components
    
    private let stickerBoardView = StampBoardCollectionView()
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setStyle()
        setHierarchy()
        setLayout()
        setDataSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        backgroundColor = .red50
    }
    
    // MARK: - DataSource Helper
    
    private func setDataSource() {
        stickerBoardDataSource = UICollectionViewDiffableDataSource(
            collectionView: stickerBoardView.getCollectionView(),
            cellProvider: { collectionView, indexPath, itemIdentifier in
                guard let section = StampBoardSection(rawValue: indexPath.section) else { return .init() }
                
                switch section {
                case .summary:
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: SummaryCell.identifier,
                        for: indexPath
                    ) as! SummaryCell
                    
                    if case let .summary(collected, completed) = itemIdentifier {
                        cell.configureItem(
                            currentSticker: "\(collected)",
                            totalSticker: "\(StampBoardSection.defaultBoard.totalStamp)",
                            totalBoard: "\(completed)"
                        )
                    }
                    
                    return cell
                    
                case .defaultBoard:
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: StampCell.identifier,
                        for: indexPath
                    ) as! StampCell
                    
                    if case let .stickers(stickers) = itemIdentifier {
                        let backgroundBoard = StampBoardSection.defaultBoard.type.flatMap { $0 }
                        if backgroundBoard.indices.contains(indexPath.item) {
                            cell.configureDashedLine(with: backgroundBoard[indexPath.item])
                        }
                        cell.configureStamp(with: stickers)
                    }
                    return cell
                }
            })
        stickerBoardView.setDataSource(stickerBoardDataSource)
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            stickerBoardView
        ]
            .forEach { addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        stickerBoardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
