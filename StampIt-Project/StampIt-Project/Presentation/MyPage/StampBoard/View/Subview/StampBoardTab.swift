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
    
    var stampBoardDataSource: UICollectionViewDiffableDataSource<StampBoardSection, StampBoardItem>!
    
    private weak var footerView: PageControlFooterView?
    
    let footerPageRelay = BehaviorRelay<(Int)>(value: (.zero))
    let disposeBag = DisposeBag()

    // MARK: - UI Components
    
    private let stampBoardView = StampBoardCollectionView()
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setStyle()
        setHierarchy()
        setLayout()
        setDataSource()
        setFooter()
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
        stampBoardView.scrollDelegate = delegate
    }
    
    func setCollectionViewDelegate(_ delegate: UICollectionViewDelegate) {
        stampBoardView.setCollectionViewDelegate(delegate)
    }
    
    // TODO: 사용후 필요한 메소드만 getter 로 생성
    func getCollectionView() -> UICollectionView {
        stampBoardView.getCollectionView()
    }
    
    // MARK: - DataSource Helper
    
    private func setDataSource() {
        stampBoardDataSource = UICollectionViewDiffableDataSource(
            collectionView: stampBoardView.getCollectionView(),
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
                            currentStamp: "\(collected)",
                            totalStamp: "\(Stamp.totalStamp)",
                            totalBoard: "\(completed)"
                        )
                    }
                    return cell
                    
                case .page:
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: StampCell.identifier,
                        for: indexPath
                    ) as! StampCell
                    
                    if case let .stamp(stamp) = itemIdentifier {
                        /// .page 섹션 하나 안에 셀 (페이징된 모든 스티커 아이템) 을 다 그려서 30 단위로 indexPath.item 증가
                        let itemIndexInPage = indexPath.item % Stamp.totalStamp

                        let backgroundBoard = StampBoardSection.page.type.flatMap { $0 }
                        
                        if backgroundBoard.indices.contains(itemIndexInPage) {
                            cell.configureDashedLine(with: backgroundBoard[itemIndexInPage])
                        }
                        
                        cell.configureStamp(with: stamp)
                    }
                    return cell
                }
            })
        stampBoardView.setDataSource(stampBoardDataSource)
    }
    
    private func setFooter() {
        stampBoardDataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            
            let sections = StampBoardSection.allCases
            
            if sections[indexPath.section] == .page {
                guard kind == UICollectionView.elementKindSectionFooter,
                      let self else {
                    return UICollectionReusableView()
                }
                
                let footer = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: PageControlFooterView.identifier,
                    for: indexPath
                ) as! PageControlFooterView
                
                self.footerView = footer
                
                footerPageRelay
                    .distinctUntilChanged { $0 == $1 }
                    .bind(with: self) { owner, page in
                        footer.configure(
                            numberOfPages: page,
                            currentPage: .zero
                        )
                    }
                    .disposed(by: disposeBag)
                
                return footer
            }
            
            return UICollectionReusableView()
        }
    }
    
    func updateFooterPage(to page: Int) {
        footerView?.setCurrentPage(page)
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            stampBoardView
        ]
            .forEach { addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        stampBoardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
