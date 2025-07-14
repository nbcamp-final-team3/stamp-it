//
//  NoticeListViewController.swift
//  StampIt-Project
//
//  Created by daeun on 7/9/25.
//

import UIKit

final class NoticeListViewController: UIViewController {
    let viewModel: NoticeListViewModel!

    init(viewModel: NoticeListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
