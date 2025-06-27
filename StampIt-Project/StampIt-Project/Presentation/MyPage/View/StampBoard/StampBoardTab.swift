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
        backgroundColor = .clear
    }
    
    // MARK: - Delegate Helper
    
    func setScrollDelegate(_ delegate: StampBoardScrollDelegate) {
        stickerBoardView.scrollDelegate = delegate
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
                            totalSticker: "\(StampBoardSection.totalStamp)",
                            totalBoard: "\(completed)"
                        )
                    }
                    return cell
                    
                case .page:
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: StampCell.identifier,
                        for: indexPath
                    ) as! StampCell
                    
                    if case let .sticker(sticker) = itemIdentifier {
                        /// .page 섹션 하나 안에 셀 (페이징된 모든 스티커 아이템) 을 다 그려서 30 단위로 indexPath.item 증가
                        let itemIndexInPage = indexPath.item % StampBoardSection.totalStamp
                        
                        let backgroundBoard = StampBoardSection.page.type.flatMap { $0 }
                        
                        if backgroundBoard.indices.contains(itemIndexInPage) {
                            cell.configureDashedLine(with: backgroundBoard[itemIndexInPage])
                        }
                        
                        cell.configureStamp(with: sticker)
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
