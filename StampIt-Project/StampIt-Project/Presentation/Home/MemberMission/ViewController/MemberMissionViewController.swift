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

    private let memberMissionView = MemberMissionView()

    // MARK: - Life Cycles

    init(viewModel: MemberMissionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = memberMissionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    // MARK: - Bind

    private func bind() {
        viewModel.action.accept(.viewDidLoad)

        viewModel.state.missions
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, items in
                owner.memberMissionView.updateSnapshot(withItems: items, toSection: .mission)
            }
            .disposed(by: disposeBag)
    }

}
