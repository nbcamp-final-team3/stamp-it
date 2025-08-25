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

    private let bellButton = UIButton().then {
        $0.setImage(UIImage(named: Navigation.bellButton), for: .normal)
    }
    private lazy var navigationBar = DefaultNavigationBar(.logoWithItem).then {
        $0.addRightItem(bellButton)
    }
    private let homeView = HomeView()
    private var activeToasts: [String: ToastView] = [:] // key: missionID

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
        viewModel.action.accept(.viewDidLoad)
        bindGroupOrganizationView()
        bindDashboardView()
        bindToastView()
        bindBellButton()
    }

    private func bindBellButton() {
        bellButton.rx.tap
            .map { HomeViewModel.Action.checkNotice }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.isPushNoticeListVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: pushNoticeListVC)
            .disposed(by: disposeBag)
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

        viewModel.state.isPushSendInvitationVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, _ in
                let sendInviteVC = DIContainer.shared.makeSendInviteViewController()
                owner.navigationController?.pushViewController(sendInviteVC, animated: true)
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

    private func bindDashboardView() {
        homeView.didTapMissionCompleteButton
            .map { HomeViewModel.Action.didTapMissonCompleteButton($0) }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        homeView.didTapMoreMyMissionButton
            .map { HomeViewModel.Action.didTapMoreMyMissions }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        homeView.didTapMoreMemberMissionButton
            .map { HomeViewModel.Action.didTapMoreMemberMissions }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        homeView.selectMember
            .map { HomeViewModel.Action.didSelectReceivedMember($0) }
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

        viewModel.state.myMissions
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.homeView.updateSnapshot(withItems: items, toSection: .myMission)
            }
            .disposed(by: disposeBag)

        viewModel.state.isPushMyMissionVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: pushMyMissionVC)
            .disposed(by: disposeBag)

        viewModel.state.memberFilter
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.homeView.updateSnapshot(withItems: items, toSection: .memberFilter)
                owner.homeView.setDefaultSelection()
            }
            .disposed(by: disposeBag)

        viewModel.state.memberMissionsForDisplay
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.homeView.updateSnapshot(withItems: items, toSection: .memberMission)
            }
            .disposed(by: disposeBag)

        viewModel.state.isPushMemberMissionVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: pushMemberMissionVC)
            .disposed(by: disposeBag)
    }

    private func bindToastView() {
        viewModel.state.completionCanceledMission
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, missionID in
                owner.activeToasts[missionID]?.dismiss(duration: 0)
                owner.activeToasts[missionID] = nil
            }
            .disposed(by: disposeBag)

        viewModel.state.isShowStampReceived
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, value in
                let (missionID, message) = value
                let toastView = ToastView(withCancelButton: true)
                owner.activeToasts[missionID] = toastView

                toastView.show(in: owner.homeView, duration: 3, message: message, type: .success)

                Observable.just(())
                    .delay(.seconds(3), scheduler: MainScheduler.instance)
                    .take(until: toastView.didTapCancelButton)
                    .bind(with: self) { owner, _ in
                        owner.activeToasts[missionID] = nil
                    }
                    .disposed(by: toastView.disposeBag)

                toastView.didTapCancelButton
                    .map { HomeViewModel.Action.didTapCompleteCancelButton }
                    .bind(to: owner.viewModel.action)
                    .disposed(by: toastView.disposeBag)
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
            // SafeArea의 25%만 올라오는 custom detent 생성
            let customDetent = UISheetPresentationController.Detent.custom(
                resolver: { context in
                    let calculated = context.maximumDetentValue * 0.35
                    return max(calculated, 388)
                }
            )

            sheet.detents = [customDetent]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 32
        }
        present(vc, animated: true)
    }

    private func pushNoticeListVC() {
        let noticeListVC = DIContainer.shared.makeNoticeListViewController()
        navigationController?.pushViewController(noticeListVC, animated: true)
    }

    private func pushMyMissionVC() {
        let myMissionVC = DIContainer.shared.makeMyMissionViewController(
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
