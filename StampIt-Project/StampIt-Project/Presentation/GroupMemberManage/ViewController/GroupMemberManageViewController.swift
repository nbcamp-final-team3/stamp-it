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
    private let toastView = ToastView()

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
                .subscribe(onNext: { [weak self] _ in
                    if item.isCurrentUser {
                        // 자기 자신인 경우 토스트 메시지 표시
                        self?.showToastMessage(message: "자기 자신에게는 적용할 수 없습니다.", type: .failure)
                    } else {
                        // 다른 멤버인 경우 옵션 시트 표시
                        self?.viewModel.action.accept(.didTapCardOptionButton(memberId: item.id))
                    }
                })
                .disposed(by: self.disposeBag)
            
            return cell
        }
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
            .drive(with: self) { owner, memberId in
                owner.showMemberManageOptionSheet(memberId: memberId)
            }
            .disposed(by: disposeBag)

        // 토스트 메시지 표시 (에러 및 성공 메시지 통합)
        viewModel.state.showToast
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, message in
                owner.showToastMessage(message: message, type: .failure)
            }
            .disposed(by: disposeBag)

        // 성공 메시지 표시 (토스트로 변경)
        viewModel.state.showSuccess
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, message in
                owner.showToastMessage(message: message, type: .success)
            }
            .disposed(by: disposeBag)

        // 멤버 목록 업데이트
        viewModel.state.members
            .asDriver()
            .drive(with: self) { owner, members in
                owner.updateMembersList(members: members)
            }
            .disposed(by: disposeBag)

        // 초기 데이터 로드
        viewModel.action.accept(.viewDidLoad)
    }

    private func updateMembersList(members: [Member]) {
        var snapshot = NSDiffableDataSourceSnapshot<GroupMemberManageViewModel.Section, GroupMemberManageViewModel.Item>()
        snapshot.appendSections([.main])

        // 현재 사용자 정보 가져오기
        let currentUserId = viewModel.getCurrentUserId()

        let items = members.map { member in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy년 MM월 dd일"
            let formattedDate = dateFormatter.string(from: member.joinedAt)
            
            return GroupMemberManageViewModel.Item(
                id: member.userID, 
                name: member.nickname,
                date: "그룹 가입일: \(formattedDate)",
                image: UIImage(named: member.profileImage ?? "profileImage1"),
                isCurrentUser: member.userID == currentUserId
            )
        }
        
        snapshot.appendItems(items, toSection: .main)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    private func showMemberManageOptionSheet(memberId: String) {
        // 해당 멤버의 정보 찾기
        let targetMember = viewModel.state.members.value.first { $0.userID == memberId }
        let memberNickname = targetMember?.nickname ?? "멤버"
        
        let vm = MemberManageOptionViewModel(memberNickname: memberNickname)
        let vc = MemberManageOptionViewController(viewModel: vm)

        vc.didTapConfirmButton
            .map { GroupMemberManageViewModel.Action.didReceiveMemberManageType($0, memberId: memberId) }
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

    private func showToastMessage(message: String, type: ToastType = .failure) {
        toastView.show(in: view, message: message, type: type)
    }

}

extension GroupMemberManageViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    // navigationController의 viewControllers가 2개 이상일 때만 pop 허용
    return navigationController?.viewControllers.count ?? 0 > 1
  }
}



