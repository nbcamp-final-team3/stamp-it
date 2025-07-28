//
//  NoticeView.swift
//  StampIt-Project
//
//  Created by daeun on 7/23/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxRelay

final class NoticeView: UIView {

    // MARK: - Actions

    // MARK: - Properties

    var dataSource: UICollectionViewDiffableDataSource<NoticeSection, HomeNotice>?

    // MARK: - UI Components

    lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.register(NoticeCell.self, forCellWithReuseIdentifier: NoticeCell.identifier)
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setHierarchy()
        setConstraints()
        setDataSource()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            collectionView,
        ].forEach { addSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Set Data Source

    private func setDataSource() {
        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, notice in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: NoticeCell.identifier,
                for: indexPath
            ) as! NoticeCell

            cell.configure(item: notice)

            return cell
        }

        var initialSnapshot = NSDiffableDataSourceSnapshot<NoticeSection, HomeNotice>()
        initialSnapshot.appendSections(NoticeSection.allCases)
        dataSource?.apply(initialSnapshot, animatingDifferences: false)
    }

    // MARK: - Bind

    private func bind() {
    }

    // MARK: - CollectionView Layout Helper

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { section, environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(100)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(100)
            )
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)

            return section
        }
    }

    // MARK: - Methods

    func updateSnapshot(withItems items: [HomeNotice], toSection section: NoticeSection) {

    }
}
