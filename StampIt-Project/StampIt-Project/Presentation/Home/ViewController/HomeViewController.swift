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

    private let navigationBar = DefaultNavigationBar(.logoWithItem)
    private let homeView = HomeView()
    private let toastView = ToastView(withCancelButton: true)

    // MARK: - Life Cycles

    init(viewModel: HomeViewModel) {
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

    override func viewWillAppear(_ animated: Bool) {
        viewModel.action.accept(.viewWillAppear)
    }

    // MARK: - Set Styles

    private func setStyles() {
        navigationController?.navigationBar.isHidden = true
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        [
            navigationBar,
            homeView,
        ].forEach { view.addSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
        }

        homeView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.directionalHorizontalEdges.bottom.equalToSuperview()
        }
    }

    // MARK: - Bind

    private func bind() {
        bindGroupOrganizationView()
        bindDashboardView()
        bindToastView()
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

        homeView.didTapMoreSendedMissionButton
            .map { HomeViewModel.Action.didTapMoreSendedMissions }
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

        viewModel.state.isPushMemberMissionVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: pushMemberMissionVC)
            .disposed(by: disposeBag)
    }

    private func bindToastView() {
        toastView.didTapCancelButton
            .map { HomeViewModel.Action.didTapCompleteCancelButton }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.state.isShowStickerReceived,
            viewModel.state.completedMissionTitle
        )
        .asDriver(onErrorDriveWith: .empty())
        .drive { [weak self] show, missionTitle in
            guard let self else { return }
            if show {
                let message = "'\(missionTitle.truncatedTo10)' 미션을 완료했어요!"
                toastView.show(in: homeView, duration: 3, message: message)
            } else {
                toastView.dismiss(duration: 0)
            }
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
        let myMissionVC = DIContainer.shared.makeMyMissionViewController(
            user: user,
            memberCache: viewModel.memberCache
        )
        navigationController?.pushViewController(myMissionVC, animated: true)
    }

    private func pushMemberMissionVC() {
        guard let user = viewModel.state.user.value else { return }
        let memberMissionVC = DIContainer.shared.makeMemberMissionViewController(
            user: user,
            memberCache: viewModel.memberCache
        )
        navigationController?.pushViewController(memberMissionVC, animated: true)
    }
}
