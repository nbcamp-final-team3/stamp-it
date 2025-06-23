//
//  MemberDeleteViewController.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/15/25.
//

import Foundation
import UIKit
import Then
import RxSwift
import RxCocoa
import SnapKit

final class MemberDeleteViewController: UIViewController {

     // MARK: - Properties

    private let viewModel: MemberDeleteViewModel
    private let disposeBag = DisposeBag()
    private var dataSource: UICollectionViewDiffableDataSource<MemberDeleteViewModel.Section, MemberDeleteViewModel.Item>?

    // MARK: - UI

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then() {
        $0.register(MemberDeleteCell.self, forCellWithReuseIdentifier: MemberDeleteCell.reuseIdentifier)
    }


    private let exportButton = DefaultButton(type: .export)

   // MARK: - Init

    init(viewModel: MemberDeleteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bind()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(collectionView)
        view.addSubview(exportButton)
    }
    
    // MARK: - CollectionView Layout
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
        return layout
    }

    private func bind() {
        /// 멤버 목록 바인딩
        viewModel.state.members
        .asDriver()
        .drive(onNext: { [weak self] members in
            var snapshot = NSDiffableDataSourceSnapshot<MemberDeleteViewModel.Section, MemberDeleteViewModel.Item>()
            snapshot.appendSections([.main])
            snapshot.appendItems(members, toSection: .main)
            self?.dataSource.apply(snapshot, animatingDifferences: true)
        })
        .disposed(by: disposeBag)

        /// 버튼 클릭 이벤트 바인딩
        exportButton.rx.tap
        .map { MemberDeleteViewModel.Action.exportButtonTapped }
        .bind(to: viewModel.input.action)
        .disposed(by: disposeBag)

        /// 리더 여부에 따라 버튼 활성화/비활성화 바인딩
        viewModel.isLeader
            .asDriver()
            .drive(exportButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }

    func showExportAlert(for member: Member) {
        let alert = UIAlertController(
            title: "\(member.nickname)님을 그룹에서 내보낼까요?",
            message: "내보내신 후 복구는 불가능해요",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "내보내기", style: .destructive) { _ in
            self.viewModel.action.accept(.exportMember(memberID: member.userID))
        })
        present(alert, animated: true)
    }

}
