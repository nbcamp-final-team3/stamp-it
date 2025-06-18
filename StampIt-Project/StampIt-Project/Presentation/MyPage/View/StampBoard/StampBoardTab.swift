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
    
    private let stickerSummaryView = StampSummary()
    private let stickerBoardView = StampBoard()
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setLayout()
        setDataSource()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Bind
    
    private func bind() {
        stickerSummary.bind(with: self) { owner, summary in
            owner.stickerSummaryView.configureItem(
                currentSticker: "\(summary.collectedSticker)",
                totalSticker: "\(StampBoardSection.defaultBoard.totalStamp)",
                totalBoard: "\(summary.completedBoard)\(MyPage.StampBoard.unit)"
            )
        }.disposed(by: disposeBag)
    }
    
    // MARK: - DataSource Helper
    
    private func setDataSource() {
        stickerBoardDataSource = UICollectionViewDiffableDataSource(
            collectionView: stickerBoardView.getCollectionView(),
            cellProvider: { collectionView, indexPath, itemIdentifier in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: StampCell.identifier,
                    for: indexPath
                ) as! StampCell
                
                let backgroundBoard = StampBoardSection.defaultBoard.type.flatMap { $0 }
                if backgroundBoard.indices.contains(indexPath.item) {
                    cell.configureDashedLine(with: backgroundBoard[indexPath.item])
                }
                cell.configureStamp(with: itemIdentifier)
                return cell
            })
        stickerBoardView.setDataSource(stickerBoardDataSource)
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            stickerSummaryView,
            stickerBoardView
        ]
            .forEach { addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        stickerSummaryView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(30)
            $0.directionalHorizontalEdges.equalToSuperview().inset(16)
        }
        
        stickerBoardView.snp.makeConstraints {
            $0.top.equalTo(stickerSummaryView.snp.bottom).offset(34)
            $0.leading.equalToSuperview().inset(36)
            $0.trailing.equalToSuperview().inset(StickerType.imageSize / 3)
            $0.bottom.equalToSuperview()
        }
    }
}
