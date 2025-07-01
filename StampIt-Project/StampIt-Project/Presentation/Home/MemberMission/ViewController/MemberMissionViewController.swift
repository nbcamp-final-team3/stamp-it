//
//  MemberMissionViewController.swift
//  StampIt-Project
//
//  Created by daeun on 6/17/25.
//

import UIKit
import RxSwift
import RxCocoa

final class MemberMissionViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: MemberMissionViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "멤버 미션"))
    private let memberMissionView = MemberMissionView()

    // MARK: - Life Cycles

    init(viewModel: MemberMissionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setStyles()
        setHierarchy()
        setConstraints()
        bind()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    // MARK: - Set Styles

    private func setStyles() {
        view.backgroundColor = .FFFFFF
        navigationController?.navigationBar.isHidden = true
        tabBarController?.tabBar.isHidden = true
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            navigationBar,
            memberMissionView,
        ].forEach { view.addSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
        }

        memberMissionView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.directionalHorizontalEdges.bottom.equalToSuperview()
        }
    }
    // MARK: - Bind

    private func bind() {
        viewModel.action.accept(.viewDidLoad)

        navigationBar.backTapped
            .map { MemberMissionViewModel.Action.didTapBackButton }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        memberMissionView.selectFilter
            .map { MemberMissionViewModel.Action.selectFilter($0) }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        memberMissionView.didTapSendMissionButton
            .map { MemberMissionViewModel.Action.didTapSendMission }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.members
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.memberMissionView.updateSnapshot(withItems: items, toSection: .filter)
            }
            .disposed(by: disposeBag)

        viewModel.state.selectedMember
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, index in
                owner.memberMissionView.setFilterSelection(index: index)
            }
            .disposed(by: disposeBag)

        viewModel.state.missions
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.memberMissionView.updateSnapshot(withItems: items, toSection: .mission)
            }
            .disposed(by: disposeBag)

        viewModel.state.isPopVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

        viewModel.state.isMoveToMissionTap
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                NavigationManager.shared.switchTab(to: 1, in: owner.tabBarController!)
                owner.navigationController?.popViewController(animated: false)
            }
            .disposed(by: disposeBag)
    }

}
