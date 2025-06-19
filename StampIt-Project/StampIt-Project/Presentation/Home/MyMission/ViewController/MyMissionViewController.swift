//
//  MyMissionViewController.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import UIKit
import RxSwift
import RxCocoa

final class MyMissionViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: MyMissionViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "내 미션"))
    private let myMissionView = MyMissionView()
    private let toastView = ToastView(withCancelButton: true)

    // MARK: - Life Cycles

    init(viewModel: MyMissionViewModel) {
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
            myMissionView,
        ].forEach { view.addSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
        }

        myMissionView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.directionalHorizontalEdges.bottom.equalToSuperview()
        }
    }

    // MARK: - Bind

    private func bind() {
        viewModel.action.accept(.viewDidLoad)

        navigationBar.backTapped
            .map { MyMissionViewModel.Action.didTapBackButton }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        myMissionView.didTapStatusButton
            .map { MyMissionViewModel.Action.didTapStatusButton($0) }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        toastView.didTapCancelButton
            .map { MyMissionViewModel.Action.didTapCompleteCancelButton }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.isPopVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

        viewModel.state.missions
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.myMissionView.updateSnapshot(withItems: items, toSection: .mission)
            }
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
                toastView.show(in: myMissionView, duration: 3, message: message, type: .success)
            } else {
                toastView.dismiss(duration: 0)
            }
        }
        .disposed(by: disposeBag)
    }
}
