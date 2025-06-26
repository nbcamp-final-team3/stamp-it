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

    // MARK: - Actions

    let didTapStatusButton = PublishRelay<MyMissionItem>()
    let selectFilter = PublishRelay<Int>()

    // MARK: - Properties

    private let disposeBag = DisposeBag()
    private var dataSource: UICollectionViewDiffableDataSource<MyMissionSection, MyMissionItem>?

    // MARK: - UI Components

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.backgroundColor = .clear
        $0.register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.reuseIdentifier)
        $0.register(
            AssignedMissionCell.self,
            forCellWithReuseIdentifier: AssignedMissionCell.identifier
        )
    }

    private let noResultsView = NoResultsView().then {
        $0.configureContent(title: "아직 부여된 미션이 없어요")
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
            noResultsView,
            collectionView,
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
            case .status(let status):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: FilterCell.reuseIdentifier,
                    for: indexPath
                ) as! FilterCell

                cell.configure(title: status.displayTitle)

                return cell

            case .mission(let mission):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: AssignedMissionCell.identifier,
                    for: indexPath
                ) as! AssignedMissionCell

                cell.configureAsReceived(with: mission)

                cell.didTapStatusButton
                    .filter { item.mission!.status == .assigned }
                    .bind(with: self) { owner, _ in
                        owner.didTapStatusButton.accept(item)
                    }
                    .disposed(by: cell.disposeBag)

                return cell
            }
        }

        var snapshot = NSDiffableDataSourceSnapshot<MyMissionSection, MyMissionItem>()
        snapshot.appendSections(MyMissionSection.allCases)
        dataSource?.apply(snapshot)
    }

    // MARK: - Bind

    private func bind() {
        collectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .map { $0.item }
            .bind(to: selectFilter)
            .disposed(by: disposeBag)
    }

    // MARK: - Methods

    func updateSnapshot(withItems items: [MyMissionItem], toSection section: MyMissionSection) {
        guard var snapshot = dataSource?.snapshot() else { return }
        let itemsToDelete = snapshot.itemIdentifiers(inSection: section)
        snapshot.deleteItems(itemsToDelete)
        snapshot.appendItems(items, toSection: section)
        dataSource?.apply(snapshot, animatingDifferences: false)
        noResultsView.isHidden = !items.isEmpty
    }

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] section, environment in
            guard let self else { return nil }

            let section = MyMissionSection.allCases[section]

            switch section {
            case .filter:
                return .createFilterSection()
            case .mission:
                return createMissionSection()
            }
        }
    }

    private func createMissionSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(80)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(80)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 6
        section.contentInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
        return section
    }

    func setDefaultSelection() {
        let section = MyMissionSection.allCases.firstIndex(of: .filter)!
        guard collectionView.numberOfItems(inSection: section) > 0 else { return }
        let indexPath = IndexPath(item: 0, section: section)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
    }
}

extension MyMissionView: UICollectionViewDelegate {
  func collectionView(
    _ collectionView: UICollectionView,
    shouldSelectItemAt indexPath: IndexPath
  ) -> Bool {
      return indexPath.section == MyMissionSection.allCases.firstIndex(of: .filter)!
  }
}
