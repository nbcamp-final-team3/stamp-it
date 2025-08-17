//
//  NoticeListViewController.swift
//  StampIt-Project
//
//  Created by daeun on 7/9/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class NoticeListViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: NoticeListViewModel!
    private lazy var navigator = DefaultNoticeNavigator(nav: self.navigationController, tab: self.tabBarController)

    // MARK: - UI Components

    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "알림"))
    private let noticeView = NoticeView()

    // MARK: - Properties

    private let disposeBag = DisposeBag()

    // MARK: - Life Cycles

    init(viewModel: NoticeListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setStyle()
        setHierarchy()
        setConstraints()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setStyle() {
        view.backgroundColor = .FFFFFF
    }

    private func setHierarchy() {
        [
            navigationBar,
            noticeView,
        ].forEach { view.addSubview($0) }
    }

    private func setConstraints() {
        navigationBar.snp.makeConstraints { make in
            make.top.directionalHorizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }

        noticeView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.directionalHorizontalEdges.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
    }

    private func bind() {
        viewModel.action.accept(.load)

        navigationBar.backTapped
            .map { NoticeListViewModel.Action.navigateBack }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)
        
        noticeView.selectedRow
            .map { NoticeListViewModel.Action.selectNotice($0) }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.isNavigateBack
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

        viewModel.state.notices
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.noticeView.updateSnapshot(withItems: items, toSection: .list)
            }
            .disposed(by: disposeBag)
        
        viewModel.state.noticeTarget
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, category in
                owner.navigator.show(by: category)
            }
            .disposed(by: disposeBag)
    }
}
