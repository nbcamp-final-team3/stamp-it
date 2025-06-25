//
//  GroupMemberManageViewController.swift
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

final class GroupMemberManageViewController: UIViewController {

     // MARK: - Properties

    private let viewModel: GroupMemberManageViewModel
    private let disposeBag = DisposeBag()
    private var dataSource: UICollectionViewDiffableDataSource<GroupMemberManageViewModel.Section, GroupMemberManageViewModel.Item>?

    // MARK: - UI

    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "멤버 관리"))
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then() {
        $0.register(GroupMemberCardCell.self, forCellWithReuseIdentifier: GroupMemberCardCell.reuseIdentifier)
    }

   // MARK: - Init

    init(viewModel: GroupMemberManageViewModel) {
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
        setupDataSource()
        bind()
        setupNavigation()
    }

    // MARK: - UI Setup

    private func setupNavigation() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

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
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(110)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<GroupMemberManageViewModel.Section, GroupMemberManageViewModel.Item>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupMemberCardCell.reuseIdentifier, for: indexPath) as! GroupMemberCardCell
            cell.configure(with: item, at: indexPath)

            cell.optionButtonTapped
                .map { _ in GroupMemberManageViewModel.Action.didTapCardOptionButton }
                .bind(to: self.viewModel.action)
                .disposed(by: self.disposeBag)
            
            return cell
        }
        
        // 테스트 데이터 추가
        var snapshot = NSDiffableDataSourceSnapshot<GroupMemberManageViewModel.Section, GroupMemberManageViewModel.Item>()
        snapshot.appendSections([.main])

        // TODO: 실제 DB에서 데이터 받아오면 삭제 예정
        let testItems = [
            GroupMemberManageViewModel.Item(id: "1", name: "김철수"),
            GroupMemberManageViewModel.Item(id: "2", name: "이영희"),
            GroupMemberManageViewModel.Item(id: "3", name: "박민수")
        ]
        
        snapshot.appendItems(testItems, toSection: .main)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func bind() {
        // 네비게이션바 뒤로가기 버튼
        navigationBar.backTapped
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

        // 옵션 시트 표시
        viewModel.state.showOptionSheet
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, _ in
                owner.showMemberManageOptionSheet()
            }
            .disposed(by: disposeBag)

        // 리더 위임 처리
        viewModel.state.isLeaderMandate
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, _ in
                owner.handleLeaderMandate()
            }
            .disposed(by: disposeBag)

        // 멤버 내보내기 처리
        viewModel.state.isMemberExport
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, _ in
                owner.handleMemberExport()
            }
            .disposed(by: disposeBag)
    }

    private func handleLeaderMandate() {
        // 리더 위임 로직 구현
        print("리더 위임 처리")
        // TODO: 실제 리더 위임 로직 구현
    }

    private func handleMemberExport() {
        // 멤버 내보내기 로직 구현
        print("멤버 내보내기 처리")
        // TODO: 실제 멤버 내보내기 로직 구현
    }

    private func showMemberManageOptionSheet() {
        let vm = MemberManageOptionViewModel()
        let vc = MemberManageOptionViewController(viewModel: vm)

        vc.didTapConfirmButton
            .map { GroupMemberManageViewModel.Action.didReceiveMemberManageType($0) }
            .bind(to: viewModel.action)
            .disposed(by: vc.disposeBag)

        if let sheet = vc.sheetPresentationController {
            // SafeArea의 25%만 올라오는 custom detent 생성
            let customDetent = UISheetPresentationController.Detent.custom(
                // 식별자 선언은 선택의 영역인데 최대한 documents를 따라가고 싶어서 넣었습니다.
                identifier: .init("small"),
                resolver: { context in
                    let calculated = context.maximumDetentValue * 0.35
                    return max(calculated, 350)
                }
            )
            
            sheet.detents = [customDetent]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 32
        }
        present(vc, animated: true)
    }

}

extension GroupMemberManageViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    // navigationController의 viewControllers가 2개 이상일 때만 pop 허용
    return navigationController?.viewControllers.count ?? 0 > 1
  }
}



