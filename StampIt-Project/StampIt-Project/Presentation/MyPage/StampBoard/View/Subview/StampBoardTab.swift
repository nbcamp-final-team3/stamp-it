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

    // MARK: - Properties

    private typealias DataSource = UICollectionViewDiffableDataSource<StampBoardSection, StampBoardItem>
    private var dataSource: DataSource!

    private var numberOfPages: Int = .zero
    private var currentPage: Int = .zero
    var currentPageValue: Int { currentPage }

    // MARK: - UI Components

    private lazy var collectionView = UICollectionView(
        frame: .zero, collectionViewLayout: createCompositionalLayout()
    ).then {
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = false
        $0.alwaysBounceHorizontal = false
        $0.decelerationRate = .fast
    }
    private weak var footerView: PageControlFooterView?

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
    
    // MARK: - External Interface

    func setDelegate(_ target: StampBoardViewController) {
        collectionView.delegate = target
    }

    func setTotalPages(_ count: Int) {
        numberOfPages = count
        footerView?.configure(numberOfPages: count, currentPage: currentPage)
    }

    func setCurrentPage(_ page: Int) {
        currentPage = page
        footerView?.setCurrentPage(page)
    }

    func render(_ state: StampBoardViewState) {
        /// Snapshot 적용
        var snapshot = NSDiffableDataSourceSnapshot<StampBoardSection, StampBoardItem>()
        snapshot.appendSections([.summary, .board])

        let summaryItem: [StampBoardItem] = [
            .summary(
                collected: state.collectdStamp,
                completed: state.completedBoard
            )
        ]
        snapshot.appendItems(summaryItem, toSection: .summary)

        let maxPage = state.stampsByPage.count
        for page in 0..<maxPage {
            snapshot.appendItems(
                state.stampsByPage[page].map { .stamp($0) },
                toSection: .board
            )
        }
        dataSource.apply(snapshot, animatingDifferences: true)

        /// 총 페이지 갱신
        setTotalPages(state.numberOfPages)
    }

    // MARK: - DataSource Helper

    private func setDataSource() {
        /// Cell Register
        let summaryRegister = UICollectionView.CellRegistration<SummaryCell, (collected: Int, completed: Int)> { cell, indexPath, item in
            cell.configureItem(
                currentStamp: "\(item.collected)",
                totalStamp: "\(Stamp.totalStamp)",
                totalBoard: "\(item.completed)"
            )
        }

        let stampRegister = UICollectionView.CellRegistration<StampCell, StampBoardStamp> { cell, indexPath, stamp in
            /// .board  섹션 안에 페이징 된 모든 스티커 아이템(셀)을 다 그린다.
            /// indexPath.item 는 0부터 시작해서 계속 증가한다. (0~29, 30~59 ...)
            let itemIndexInPage = indexPath.item % Stamp.totalStamp
            let dashedLineDirection = StampBoardSection.board.type.flatMap { $0 }
            if dashedLineDirection.indices.contains(itemIndexInPage) {
                cell.configureDashedLine(with: dashedLineDirection[itemIndexInPage])
                cell.configure(with: stamp)
            }
        }

        /// Configure Data Source
        dataSource = DataSource(collectionView: collectionView) { cv, indexPath, item in
            switch item {
            case let .summary(collected, completed):
                return cv.dequeueConfiguredReusableCell(
                    using: summaryRegister,
                    for: indexPath,
                    item: (collected, completed)
                )
            case let .stamp(stamp):
                return cv.dequeueConfiguredReusableCell(
                    using: stampRegister,
                    for: indexPath,
                    item: stamp
                )
            }
        }
    }

    private func setFooter() {
        let footerRegister = UICollectionView.SupplementaryRegistration<PageControlFooterView>(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { [weak self] footer, elementKind, indexPath in
            guard let self else { return }
            self.footerView = footer
            footer.configure(
                numberOfPages: self.numberOfPages,
                currentPage: self.currentPage
            )
        }

        dataSource.supplementaryViewProvider = { [weak self] cv, kind, indexPath in
            guard let self else { return nil }
            guard kind == UICollectionView.elementKindSectionFooter else { return nil }

            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            guard section == .board else { return nil }

            return cv.dequeueConfiguredReusableSupplementary(
                using: footerRegister,
                for: indexPath
            )
        }
    }

    // MARK: - CompositionalLayout

    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, Environment in
            guard let section = StampBoardSection(rawValue: sectionIndex) else {
                return self?.createSummaryLayout()
            }

            switch section {
            case .summary: return self?.createSummaryLayout()
            case .board: return self?.createStampBoardLayout()
            }
        }
        return layout
    }

    private func createSummaryLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(72)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(72)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(
            top: 30,
            leading: 16,
            bottom: .zero,
            trailing: 16
        )
        return section
    }

    private func createStampBoardLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.2),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        /// 가로 그룹 (스티커 5개)
        let horizontalGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(MyPage.StampBoard.height)
        )
        let horizontalGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: horizontalGroupSize,
            subitems: Array(repeating: item, count: StampBoardSection.column)
        )

        /// 세로 그룹 (6줄 -> 총 스티커 30개)
        let verticalGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.875),
            heightDimension: .absolute(
                MyPage.StampBoard.height * CGFloat(StampBoardSection.row)
            )
        )
        let verticalGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: verticalGroupSize,
            subitems: Array(repeating: horizontalGroup, count: StampBoardSection.row)
        )

        let footerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(30)
        )
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
        footer.contentInsets.bottom = 85

        let section = NSCollectionLayoutSection(group: verticalGroup)

        let isPortrait = UIScreen.main.bounds.height > UIScreen.main.bounds.width

        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.boundarySupplementaryItems = [footer]
        section.interGroupSpacing = 30
        section.contentInsets = .init(
            top: 24,
            leading: isPortrait ? 36 : 45,
            bottom: .zero,
            trailing: isPortrait ? StampType.imageSize / 3 : -45
        )

        /// 수평 페이징 변화 감지
        section.visibleItemsInvalidationHandler = { [weak self] visibleItem, offset, environment in
            guard let self else { return }
            let page = Int(
                round(offset.x / environment.container.contentSize.width)
            )
            setCurrentPage(page)
            collectionView.backgroundColor = StampBoard(rawValue: page)?.background
        }
        return section
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            collectionView
        ]
            .forEach { addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

struct StampBoardViewState: Hashable {
    let collectdStamp: Int
    let completedBoard: Int
    let stampsByPage: [[StampBoardStamp]]
    let numberOfPages: Int
}
