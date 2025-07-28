//
//  NoticeListViewController.swift
//  StampIt-Project
//
//  Created by daeun on 7/9/25.
//

import UIKit
import SnapKit

final class NoticeListViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: NoticeListViewModel!

    // MARK: - UI Components

    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "알림"))
    private let noticeView = NoticeView()

    // MARK: - Life Cycles

    init(viewModel: NoticeListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setStyle()
        setHierarchy()
        setConstraints()
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
}
