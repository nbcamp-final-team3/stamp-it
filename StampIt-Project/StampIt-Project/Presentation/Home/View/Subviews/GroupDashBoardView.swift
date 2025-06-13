//
//  GroupDashboardView.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/10/25.
//

import Foundation

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class GroupDashboardView: UIView {

    // MARK: - States

    let username = BehaviorRelay<String>(value: "유저")
    let groupName = BehaviorRelay<String>(value: "그룹")

    // MARK: - Properties

    private var dataSource: UICollectionViewDiffableDataSource<HomeSection, HomeItem>?
    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: createLayout()
    ).then {
        $0.showsVerticalScrollIndicator = false
        $0.register(MemberCompactCell.self, forCellWithReuseIdentifier: MemberCompactCell.identifier)
        $0.register(MissionCardCell.self, forCellWithReuseIdentifier: MissionCardCell.identifier)
        $0.register(AssignedMissionCell.self, forCellWithReuseIdentifier: AssignedMissionCell.identifier)
        $0.register(PlaceholderCell.self, forCellWithReuseIdentifier: PlaceholderCell.identifier)
        $0.register(
            DashboardHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: DashboardHeader.identifier
        )
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setConstraints()
        setDataSource()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        addSubview(collectionView)
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Set DataSource

    private func setDataSource() {
        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .member(let member):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MemberCompactCell.identifier,
                    for: indexPath
                ) as! MemberCompactCell
                
                cell.configureCell(with: member, type: .rank)

                return cell

            case .received(let mission):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MissionCardCell.identifier,
                    for: indexPath
                ) as! MissionCardCell

                cell.configure(with: mission)

                return cell

            case .sended(let mission):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: AssignedMissionCell.identifier,
                    for: indexPath
                ) as! AssignedMissionCell

                cell.configureAsSended(with: mission, type: .sended)

                return cell

            case .placeholder(let section):
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: PlaceholderCell.identifier,
                    for: indexPath
                ) as! PlaceholderCell

                if let text = section.placeholderText {
                    cell.configure(with: text)
                }

                return cell
            }
        }

        dataSource?.supplementaryViewProvider = { [weak self]
            collectionView, kind, indexPath -> UICollectionReusableView? in
            guard let self else { return nil }

            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: DashboardHeader.identifier,
                for: indexPath
            ) as! DashboardHeader

            let section = HomeSection.allCases[indexPath.section]
            let title: String
            let desctription: String

            switch section {
            case .ranking:
                return nil
            case .receivedMission:
                title = "내 미션"
                desctription = "이번 주 \(username.value)님에게 부여된 미션이에요"
            case .sendedMission:
                title = "멤버 미션"
                desctription = "\(username.value)님이 \(groupName.value) 멤버들에게 전달한 미션이에요"
            }

            header.configure(title: title, description: desctription)

            return header
        }

        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
        snapshot.appendSections(HomeSection.allCases)
        dataSource.apply(snapshot)
    }

    func updateSnapshot(withItems items: [HomeItem], toSection section: HomeSection) {
        guard var snapshot = dataSource?.snapshot() else { return }
        let itemForDelete = snapshot.itemIdentifiers(inSection: section)
        snapshot.deleteItems(itemForDelete)

        if items.isEmpty {
            snapshot.appendItems([.placeholder(section)], toSection: section)
        } else {
            snapshot.appendItems(items, toSection: section)
        }

        dataSource?.apply(snapshot)
    }

    // MARK: - Bind

    private func bind() {
    }

    // MARK: - Methods

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] section, environment in
            guard let self else { return nil }

            let section = HomeSection.allCases[section]
            if isOnlyPlaceholder(inSection: section) { return createEmptySection() }

            switch section {
            case .ranking:
                return createRankingSection()
            case .receivedMission:
                return createReceivedMissionSection()
            case .sendedMission:
                return createSendMissionSection()
            }
        }
    }

    private func isOnlyPlaceholder(inSection section: HomeSection) -> Bool {
        let item = dataSource?.snapshot().itemIdentifiers(inSection: section)
        return item?.count == 1 && item?.first == .placeholder(section)
    }

    private func createEmptySection() -> NSCollectionLayoutSection {
        let header = makeHeaderLayout()

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(61)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 16, leading: 16, bottom: 36, trailing: 16)
        section.boundarySupplementaryItems = [header]
        return section
    }

    private func createRankingSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(60),
            heightDimension: .absolute(107)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 12, leading: 16, bottom: 36, trailing: 16)
        return section
    }

    private func createReceivedMissionSection() -> NSCollectionLayoutSection {
        let header = makeHeaderLayout()

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(200),
            heightDimension: .absolute(290)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 20, leading: 16, bottom: 20, trailing: 16)
        section.boundarySupplementaryItems = [header]
        return section
    }

    private func createSendMissionSection() -> NSCollectionLayoutSection {
        let header = makeHeaderLayout()

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
        section.boundarySupplementaryItems = [header]
        return section
    }

    private func makeHeaderLayout() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(57)
        )

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top)

        return header
    }
}
