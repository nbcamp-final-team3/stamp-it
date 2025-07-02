//
//  StampBoard.swift
//  StampIt-Project
//
//  Created by kingj on 6/10/25.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class StampBoardCollectionView: UIView {
    
    // MARK: - Properties
    
    weak var scrollDelegate: StampBoardScrollDelegate?
    
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createCompositionalLayout()
    ).then {
        $0.register(
            SummaryCell.self,
            forCellWithReuseIdentifier: SummaryCell.identifier
        )
        $0.register(
            StampCell.self,
            forCellWithReuseIdentifier: StampCell.identifier
        )
        $0.register(
            PageControlFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: PageControlFooterView.identifier
        )
        $0.backgroundColor = .clear
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = false
        $0.alwaysBounceHorizontal = false
        $0.decelerationRate = .fast
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
    
    // MARK: - Setter & Getter
    
    // TODO: 사용후 필요한 메소드만 getter 로 생성
    func getCollectionView() -> UICollectionView {
        collectionView
    }
    
    func setDataSource(
        _ dataSource: UICollectionViewDiffableDataSource<StampBoardSection, StampBoardItem>
    ) {
        collectionView.dataSource = dataSource
    }

    // MARK: - CompositionalLayout

    private func createCompositionalLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let section = StampBoardSection(rawValue: sectionIndex) else {
                return self?.createStampSummaryLayout()
            }
            
            switch section {
            case .summary: return self?.createStampSummaryLayout()
            case .page: return self?.createStampBoardLayout()
            }
        }
        return layout
    }
    
    private func createStampSummaryLayout() -> NSCollectionLayoutSection {
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
            bottom: 0,
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
            subitems: Array(repeating: item, count: 5)
        )
        
        /// 세로 그룹 (6줄 -> 총 스티커 30개)
        let verticalGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.875),
            heightDimension: .absolute(MyPage.StampBoard.height * 6)
        )
        let verticalGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: verticalGroupSize,
            subitems: Array(repeating: horizontalGroup, count: 6)
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
            bottom: 0,
            trailing: isPortrait ? StickerType.imageSize / 3 : -45
        )
        
        /// 수평 페이징 변화 감지
        section.visibleItemsInvalidationHandler = { [weak self] visibleItems, offset, environment in
            let page = Int(
                round(offset.x / environment.container.contentSize.width)
            )
            self?.scrollDelegate?.didScrollToPage(page)
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
