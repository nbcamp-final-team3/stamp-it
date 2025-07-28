//
//  NoticeListViewController.swift
//  StampIt-Project
//
//  Created by daeun on 7/9/25.
//

import UIKit

final class NoticeListViewController: UIViewController {

    // MARK: - Dependencies

    let viewModel: NoticeListViewModel!

    // MARK: - UI Components

    let noticeView = NoticeView()

    // MARK: - Life Cycles

    init(viewModel: NoticeListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = noticeView
    }

}
