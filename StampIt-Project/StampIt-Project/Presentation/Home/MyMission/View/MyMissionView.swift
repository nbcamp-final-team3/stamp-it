//
//  MyMissionView.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxRelay

final class MyMissionView: UIView {

    // MARK: - Properties

    private let disposeBag = DisposeBag()
    private var dataSource: UICollectionViewDiffableDataSource<MyMissionSection, MyMissionItem>?

    // MARK: - UI Components

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.register(
            AssignedMissionCell.self,
            forCellWithReuseIdentifier: AssignedMissionCell.identifier
        )
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
            make.top.equalTo(safeAreaLayoutGuide)
            make.directionalHorizontalEdges.bottom.equalToSuperview()
        }
    }

    // MARK: - Set DataSource

    private func setDataSource() {
        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .mission(let mission):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: AssignedMissionCell.identifier,
                    for: indexPath
                ) as! AssignedMissionCell

                cell.configureAsReceived(with: mission)

                return cell
            }
        }

        var snapshot = NSDiffableDataSourceSnapshot<MyMissionSection, MyMissionItem>()
        snapshot.appendSections(MyMissionSection.allCases)
        dataSource?.apply(snapshot)
    }

    // MARK: - Bind

    private func bind() {
    }

    // MARK: - Methods

    func updateSnapshot(withItems items: [MyMissionItem], toSection section: MyMissionSection) {
        guard let dataSource else { return }
        var snapshot = dataSource.snapshot()
        let itemsToDelete = snapshot.itemIdentifiers(inSection: section)
        snapshot.deleteItems(itemsToDelete)
        snapshot.appendItems(items)
        dataSource.apply(snapshot)
    }

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] section, environment in
            guard let self else { return nil }

            let section = MyMissionSection.allCases[section]

            switch section {
            case .mission:
                return createMissionSection()
            }
        }
    }

    private func createMissionSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(74)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 6
        section.contentInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
        return section
    }
}
