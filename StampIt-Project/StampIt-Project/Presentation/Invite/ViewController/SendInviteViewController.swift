//
//  SendInviteViewController.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/7/25.
//

import Foundation
import UIKit
import Then
import SnapKit
import RxSwift

final class SendInviteViewController: UIViewController{

    // MARK: - Properties
    private let viewModel: SendInviteViewModel
    private let disposeBag = DisposeBag()

    // MARK: - Init
    init(viewModel: SendInviteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "초대하기"))

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "MascotCharacter")
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    private let helpLabel = UILabel().then {
        $0.text = "초대할 멤버에게 아래 코드를 전달해주세요"
        $0.font = .pretendard(size: 16, weight: .regular)
    }

    private let textFieldInTitle = UILabel().then {
        $0.text = "초대코드"
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray800
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    private let inviteCodeLabel = UILabel().then {
        $0.font = .pretendard(size: 16, weight: .bold)
        $0.textColor = .gray800
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let copyButton = UIButton(type: .system).then {
        $0.setImage(UIImage(named: "ContentCopy"), for: .normal)
        $0.tintColor = .gray800
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    private let inviteCodeStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 12
        $0.alignment = .center
        $0.backgroundColor = UIColor.F_2_F_2_F_2
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
        $0.layer.cornerRadius = 12
    }

    private let stackViewContainerView = UIView().then {
        $0.backgroundColor = .clear
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .FFFFFF
        setupLayout()
        bindViewModel()
        setupNavigation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    private func setupNavigation() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    private func setupLayout() {

        [navigationBar, imageView, helpLabel, stackViewContainerView]
            .forEach{ view.addSubview($0) }

        [textFieldInTitle, inviteCodeLabel, copyButton]
            .forEach { inviteCodeStackView.addArrangedSubview($0) }

        [textFieldInTitle, inviteCodeLabel].forEach {
            $0.setContentCompressionResistancePriority(.required, for: .vertical)
            $0.setContentHuggingPriority(.required, for: .vertical)
        }

        [inviteCodeStackView]
            .forEach { stackViewContainerView.addSubview($0) }


        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
        }

        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(100)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(30)
            $0.top.equalTo(navigationBar.snp.bottom).offset(140)
        }

        helpLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(imageView.snp.bottom).offset(20)
        }

        stackViewContainerView.snp.makeConstraints {
            $0.top.equalTo(helpLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(72)
        }

        inviteCodeStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        textFieldInTitle.snp.makeConstraints {
            $0.width.equalTo(60)
        }

        copyButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
    }

    // MARK: - Bind
    private func bindViewModel() {
        viewModel.state.inviteCode
            .bind(to: inviteCodeLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.state.inviteCode
            .subscribe(onNext: { code in
                UIPasteboard.general.string = code
            })
            .disposed(by: disposeBag)


        viewModel.state.showMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (type, message) in
                guard let self = self else { return }

                let toastView = ToastView()
                toastView.show(in: self.view, message: message, type: type)
            })
            .disposed(by: disposeBag)


        copyButton.rx.tap
            .map{SendInviteViewModel.Action.copyButtonTapped }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        navigationBar.backTapped
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)

    }

}
    // MARK: - UINavigationControllerDelegate

extension SendInviteViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    // navigationController의 viewControllers가 2개 이상일 때만 pop 허용
    return navigationController?.viewControllers.count ?? 0 > 1
  }
}



