//
//  MemberMissionView.swift
//  StampIt-Project
//
//  Created by daeun on 6/17/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxRelay

final class MemberMissionView: UIView {

    // MARK: - Properties

    private let disposeBag = DisposeBag()
    private var dataSource: UICollectionViewDiffableDataSource<MemberMissionSection, MemberMissionItem>?

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
    
    private let noResultsView = NoResultsView().then {
        $0.configureContent(title: "아직 전달한 미션이 없어요", withButton: true)
        $0.updateContainerTopInset(217)
        $0.isHidden = true
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
            noResultsView,
        ].forEach { addSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.directionalHorizontalEdges.bottom.equalToSuperview()
        }

        noResultsView.snp.makeConstraints { make in
            make.edges.equalTo(collectionView)
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

                cell.configureAsSended(with: mission)

                return cell
            }
        }

        var snapshot = NSDiffableDataSourceSnapshot<MemberMissionSection, MemberMissionItem>()
        snapshot.appendSections(MemberMissionSection.allCases)
        dataSource?.apply(snapshot)
    }

    // MARK: - Bind

    private func bind() {
    }

    // MARK: - Methods

    func updateSnapshot(withItems items: [MemberMissionItem], toSection section: MemberMissionSection) {
        let items = [MemberMissionItem]()
        guard var snapshot = dataSource?.snapshot() else { return }
        let itemsToDelete = snapshot.itemIdentifiers(inSection: section)
        snapshot.deleteItems(itemsToDelete)
        snapshot.appendItems(items)
        dataSource?.apply(snapshot, animatingDifferences: false)
        noResultsView.isHidden = !items.isEmpty
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
