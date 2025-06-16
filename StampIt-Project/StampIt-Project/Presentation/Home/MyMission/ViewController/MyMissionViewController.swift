//
//  MyMissionViewController.swift
//  StampIt-Project
//
//  Created by daeun on 6/16/25.
//

import UIKit
import RxSwift
import RxRelay

final class MyMissionViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: MyMissionViewModel
    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let myMissionView = MyMissionView()

    // MARK: - Life Cycles

    init(viewModel: MyMissionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = myMissionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    // MARK: - Bind

    private func bind() {
    }

}
