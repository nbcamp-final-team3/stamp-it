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

    // MARK: - Actions


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
            }
        }

        guard let dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()
        snapshot.appendSections(HomeSection.allCases)
        // TODO: 레이아웃 확인용
        snapshot.appendItems(HomeItem.homeMembers, toSection: .ranking)
        snapshot.appendItems(HomeItem.receivedMissions, toSection: .receivedMission)
        snapshot.appendItems(HomeItem.sendedMissions, toSection: .sendedMission)
        dataSource.apply(snapshot)
    }

    // MARK: - Bind

    private func bind() {
    }

    // MARK: - Methods

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { section, environment in
            let section = HomeSection.allCases[section]
            switch section {
            case .ranking:
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

            case .receivedMission:
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
                return section

            case .sendedMission:
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
    }
}

extension GroupDashboardView {
    enum HomeSection: Hashable, CaseIterable {
        case ranking
        case receivedMission
        case sendedMission
    }
}
