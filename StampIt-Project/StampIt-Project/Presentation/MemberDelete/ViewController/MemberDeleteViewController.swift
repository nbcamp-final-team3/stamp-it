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
            heightDimension: .estimated(110) // 셀 높이 조정
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, repeatingSubitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<MemberDeleteViewModel.Section, MemberDeleteViewModel.Item>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemberDeleteCell.reuseIdentifier, for: indexPath) as! MemberDeleteCell
            cell.configure(with: item)
            cell.optionButtonTapped = { [weak self] in
                guard let self = self else { return }
                self.viewModel.action.accept(.didTapCardOptionButton)
            }
            return cell
        }
        
        // 테스트 데이터 추가
        var snapshot = NSDiffableDataSourceSnapshot<MemberDeleteViewModel.Section, MemberDeleteViewModel.Item>()
        snapshot.appendSections([.main])

        // TODO: 실제 DB에서 데이터 받아오면 삭제 예정
        let testItems = [
            MemberDeleteViewModel.Item(id: "1", name: "김철수"),
            MemberDeleteViewModel.Item(id: "2", name: "이영희"),
            MemberDeleteViewModel.Item(id: "3", name: "박민수")
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

        viewModel.state.isPushReceiveInvitationVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, _ in
                let receiveInviteVC = DIContainer.shared.makeReceiveInviteViewController()
                owner.navigationController?.pushViewController(receiveInviteVC, animated: true)
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
            .map { MemberDeleteViewModel.Action.didReceiveMemberManageType($0) }
            .bind(to: viewModel.action)
            .disposed(by: vc.disposeBag)

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 32
        }
        present(vc, animated: true)
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

    func presentOptionSheet(for memberId: String) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "그룹 리더 위임하기", style: .default) { _ in
            self.viewModel.action.accept(.didRequestSelectType(.delegateLeader(memberId: memberId)))
        })
        alert.addAction(UIAlertAction(title: "멤버 내보내기", style: .destructive) { _ in
            self.viewModel.action.accept(.didRequestSelectType(.kickMember(memberId: memberId)))
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }

}

extension MemberDeleteViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    // navigationController의 viewControllers가 2개 이상일 때만 pop 허용
    return navigationController?.viewControllers.count ?? 0 > 1
  }
}



