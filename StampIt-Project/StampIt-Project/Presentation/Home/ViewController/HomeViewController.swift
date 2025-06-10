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

    private let homeView = HomeView()

    // MARK: - Life Cycles

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = homeView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    // MARK: - Bind

    private func bind() {
        homeView.didTapGroupOrganizationButton
            .map { HomeViewModel.Action.didTapGroupOrganizationButton }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.isShowSelectInvitationVC
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, _ in
                owner.showSelectInvitationVC()
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

}
