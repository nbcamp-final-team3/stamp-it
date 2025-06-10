//
//  SelectInvitationViewController.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class SelectInvitationViewController: UIViewController {

    // MARK: - Actions

    let didTapConfirmButton = PublishRelay<InvitationType>()

    // MARK: - Properties

    private let viewModel: SelectInvitationViewModel
    let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let selectInvitationView = SelectInvitationView()

    // MARK: - Life Cycles

    init(viewModel: SelectInvitationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = selectInvitationView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    // MARK: - Bind

    private func bind() {
        selectInvitationView.didTapOptionCard
            .map { SelectInvitationViewModel.Action.didTapOptionCard($0) }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        selectInvitationView.didTapConfirmButton
            .map { SelectInvitationViewModel.Action.didTapConfirmButton}
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.selectedOption
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, type in
                owner.selectInvitationView.handleSelectedOption(type)
            }
            .disposed(by: disposeBag)

        viewModel.state.isEnabledConfirmButton
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, isEnabled in
                owner.selectInvitationView.setConfirmButton(isEnabled: isEnabled)
            }
            .disposed(by: disposeBag)

        viewModel.state.dismiss
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, type in
                owner.didTapConfirmButton.accept(type)
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
}
