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

    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "멤버 내보내기"))
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then() {
        $0.register(MemberDeleteCell.self, forCellWithReuseIdentifier: MemberDeleteCell.reuseIdentifier)
    }

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
        navigationController?.navigationBar.isHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        setupUI()
        setupDataSource()
        bind()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(navigationBar)
        view.addSubview(collectionView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    // MARK: - CollectionView Layout
    
    private func createLayout() -> UICollectionViewLayout {
        // 2x2 그리드 레이아웃 설정
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(220)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 2)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<MemberDeleteViewModel.Section, MemberDeleteViewModel.Item>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberDeleteCell.reuseIdentifier, for: indexPath) as! MemberDeleteCell
            cell.configure(with: item)
            return cell
        }
        
        // 테스트 데이터 추가
        var snapshot = NSDiffableDataSourceSnapshot<MemberDeleteViewModel.Section, MemberDeleteViewModel.Item>()
        snapshot.appendSections([.main])
        
        let testItems = [
            MemberDeleteViewModel.Item(id: "1", name: "테스트 멤버 1"),
            MemberDeleteViewModel.Item(id: "2", name: "테스트 멤버 2"),
            MemberDeleteViewModel.Item(id: "3", name: "테스트 멤버 3")
        ]
        
        snapshot.appendItems(testItems, toSection: .main)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func bind() {
        /// 멤버 목록 바인딩
//        viewModel.state.members
//        .asDriver()
//        .drive(onNext: { [weak self] members in
//            var snapshot = NSDiffableDataSourceSnapshot<MemberDeleteViewModel.Section, MemberDeleteViewModel.Item>()
//            snapshot.appendSections([.main])
//            snapshot.appendItems(members, toSection: .main)
//            self?.dataSource.apply(snapshot, animatingDifferences: true)
//        })
//        .disposed(by: disposeBag)
//
//        /// 버튼 클릭 이벤트 바인딩
//        exportButton.rx.tap
//        .map { MemberDeleteViewModel.Action.exportButtonTapped }
//        .bind(to: viewModel.input.action)
//        .disposed(by: disposeBag)
//
//        /// 리더 여부에 따라 버튼 활성화/비활성화 바인딩
//        viewModel.isLeader
//            .asDriver()
//            .drive(exportButton.rx.isEnabled)
//            .disposed(by: disposeBag)
        
        // 네비게이션바 뒤로가기 버튼
        navigationBar.backTapped
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }

//    func showExportAlert(for member: Member) {
//        let alert = UIAlertController(
//            title: "\(member.nickname)님을 그룹에서 내보낼까요?",
//            message: "내보내신 후 복구는 불가능해요",
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
//        alert.addAction(UIAlertAction(title: "내보내기", style: .destructive) { _ in
//            self.viewModel.action.accept(.exportMember(memberID: member.userID))
//        })
//        present(alert, animated: true)
//    }

}

extension MemberDeleteViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    // navigationController의 viewControllers가 2개 이상일 때만 pop 허용
    return navigationController?.viewControllers.count ?? 0 > 1
  }
}

