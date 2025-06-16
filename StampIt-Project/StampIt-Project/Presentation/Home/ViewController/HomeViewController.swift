//
//  HomeViewController.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class HomeViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: HomeViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let homeView = HomeView()

    // MARK: - Life Cycles

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = homeView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        viewModel.action.accept(.viewWillAppear)
    }

    // MARK: - Bind

    private func bind() {
        bindGroupOrganizationView()
        bindDashboardView()
    }

    private func bindGroupOrganizationView() {
        homeView.didTapGroupOrganizationButton
            .map { HomeViewModel.Action.didTapGroupOrganizationButton }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.isShowGroupOrganizationView
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, isShow in
                owner.homeView.toggleView(showGroupOrganizationView: isShow)
            }
            .disposed(by: disposeBag)

        viewModel.state.isShowSelectInvitationVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, _ in
                owner.showSelectInvitationVC()
            }
            .disposed(by: disposeBag)
    }

    private func bindDashboardView() {
        homeView.didTapMissionCompleteButton
            .map { HomeViewModel.Action.didTapMissonCompleteButton($0) }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        homeView.didTapMoreReceivedMissionButton
            .map { HomeViewModel.Action.didTapMoreReceivedMissions }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.user
            .asDriver()
            .drive(with: self) { owner, user in
                guard let user else { return }
                owner.homeView.username.accept(user.nickname)
                owner.homeView.groupName.accept(user.groupName)
            }
            .disposed(by: disposeBag)

        viewModel.state.rankedMembers
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.homeView.updateSnapshot(withItems: items, toSection: .ranking)
            }
            .disposed(by: disposeBag)

        viewModel.state.receivedMissions
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.homeView.updateSnapshot(withItems: items, toSection: .receivedMission)
            }
            .disposed(by: disposeBag)

        viewModel.state.isPushMyMissionVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: pushMyMissionVC)
            .disposed(by: disposeBag)

        viewModel.state.sendedMissionsForDisplay
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.homeView.updateSnapshot(withItems: items, toSection: .sendedMission)
            }
            .disposed(by: disposeBag)
    }

    // MARK: - Methods

    private func showSelectInvitationVC() {
        let vm = SelectInvitationViewModel()
        let vc = SelectInvitationViewController(viewModel: vm)

        vc.didTapConfirmButton
            .map { HomeViewModel.Action.didReceiveInvitationType($0) }
            .bind(to: viewModel.action)
            .disposed(by: vc.disposeBag)

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 32
        }
        present(vc, animated: true)
    }

    private func pushMyMissionVC() {
        guard let user = viewModel.state.user.value else { return }
        let myMissionVC = DIContainer.shared.makeMyMissionViewController(user: user)
        navigationController?.pushViewController(myMissionVC, animated: true)
    }
}
