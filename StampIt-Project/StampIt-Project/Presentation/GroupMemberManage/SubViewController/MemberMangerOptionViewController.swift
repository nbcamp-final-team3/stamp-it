//
//  MemberMangerOptionViewController.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/25/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class MemberManageOptionViewController: UIViewController {

    // MARK: - Actions

    let didTapConfirmButton = PublishRelay<MemberManageOptionType>()

    // MARK: - Properties

    private let viewModel: MemberManageOptionViewModel
    let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let memberManageOptionView = MemberManageOptionView()

    // MARK: - Life Cycles

    init(viewModel: MemberManageOptionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = memberManageOptionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
    }

    // MARK: - Bind

    private func bind() {
        memberManageOptionView.didTapOptionCard
            .map { MemberManageOptionViewModel.Action.didTapOptionCard($0) }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        memberManageOptionView.didTapConfirmButton
            .map { MemberManageOptionViewModel.Action.didTapConfirmButton}
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.selectedOption
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, type in
                owner.memberManageOptionView.handleSelectedOption(type)
            }
            .disposed(by: disposeBag)

        viewModel.state.isEnabledConfirmButton
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, isEnabled in
                owner.memberManageOptionView.setConfirmButton(isEnabled: isEnabled)
            }
            .disposed(by: disposeBag)

        viewModel.state.dismiss
            .asDriver(onErrorDriveWith: .empty())
            .drive(with: self) { owner, type in
                owner.showConfirmationAlert(for: type)
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - Alert Methods
    
    private func showConfirmationAlert(for type: MemberManageOptionType) {
        let (title, confirmTitle) = getAlertInfo(for: type)
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { [weak self] _ in
            self?.didTapConfirmButton.accept(type)
            self?.dismiss(animated: true)
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func getAlertInfo(for type: MemberManageOptionType) -> (title: String, confirmTitle: String) {
        let memberNickname = viewModel.getMemberNickname()
        
        switch type {
        case .leaderMandate:
            return (
                title: "\(memberNickname)을(를)\n 그룹 리더로 위임할까요?",
                confirmTitle: "위임하기"
            )
        case .exportMember:
            return (
                title: "\(memberNickname)을(를)\n 그룹에서 내보낼까요?",
                confirmTitle: "내보내기"
            )
        }
    }
}
