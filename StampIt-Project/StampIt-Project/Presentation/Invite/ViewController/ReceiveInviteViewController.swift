//
//  ReceiveInviteViewController.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/9/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

/// 그룹 초대 코드 입력 화면
final class ReceiveInviteViewController: UIViewController {

    // MARK: - properties

    private let viewModel: ReceiveInviteViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: ReceiveInviteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "초대받기"))

    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "MascotCharacterGroup")
        $0.contentMode = .scaleAspectFit
    }

    private let helpLabel = UILabel().then {
        $0.text = "초대 받을 그룹의 코드를 입력해주세요"
        $0.textAlignment = .center
        $0.font = .pretendard(size: 16, weight: .medium)
        $0.textColor = .gray800
        $0.numberOfLines = 1
    }

    private let floatingLabel = UILabel().then {
        $0.text = "초대 코드"
        $0.font = .pretendard(size: 16, weight: .semibold)
        $0.textColor = .gray300
        $0.numberOfLines = 1
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)

    }

    private let textField = UITextField().then {
        $0.borderStyle = .none
        $0.backgroundColor = .clear
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
        $0.clearButtonMode = .whileEditing
    }

    private let stackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .center
        $0.distribution = .fill
    }

    private let textFieldContainer = UIView().then {
        $0.backgroundColor = .gray50
        $0.layer.cornerRadius = 12
        $0.layer.masksToBounds = true
        $0.layer.borderWidth = 0
        $0.layoutMargins = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
    }

    private let enterButton = DefaultButton(type: .enter)



    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        bindViewModel()
        textField.delegate = self
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
        // 스택에 쌓인 화면이므로 스와이프 제스처 활성화
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    private func setupLayout() {
        view.addSubview(textFieldContainer)
        textFieldContainer.addSubview(stackView)
        [floatingLabel, textField]
            .forEach { stackView.addArrangedSubview($0) }

        [navigationBar, imageView, helpLabel, enterButton]
            .forEach { view.addSubview($0) }

        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
        }

        imageView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom).offset(140)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(100)
        }

        helpLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }

        textFieldContainer.snp.makeConstraints {
            $0.top.equalTo(helpLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(72)
        }

        stackView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(12)
        }

        enterButton.snp.makeConstraints {
            $0.top.equalTo(textFieldContainer.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(52)
        }
    }

    // MARK: - Bind
    private func bindViewModel() {

        textField.rx.text.orEmpty
            .distinctUntilChanged()
            .map { ReceiveInviteViewModel.Action.codeChanged($0) }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        enterButton.rx.tap
            .map { ReceiveInviteViewModel.Action.enterButtonTapped }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.isEnterButtonEnabled
            .bind(to: enterButton.rx.isEnabled)
            .disposed(by: disposeBag)

        navigationBar.backTapped
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)

        viewModel.state.showMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (type, message) in
                guard let self = self else { return }
                let toastView = ToastView()

                toastView.show(in: self.view, message: message, type: type)
            })
            .disposed(by: disposeBag)

        viewModel.state.didCompleteInvite
            .bind(with: self) { owner, _ in
                let container = DIContainer.shared

                // 홈 탭으로 전환
                let tabBarController = MainTabBarController(container: container)
                tabBarController.selectedIndex = 0

                WindowTransitionManager.shared.changeRootViewController(to: tabBarController, duration: 0.15)
                // 현재 navigation stack에서 pop
                owner.navigationController?.popToRootViewController(animated: true)
                //스택에 쌓인 루트 뷰를 안보여주고 없애는 법

            }
            .disposed(by: disposeBag)
    }
}

// UITextFieldDelegate
extension ReceiveInviteViewController: UITextFieldDelegate {

    /// axis를 vertical로 변경
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            self.stackView.axis = .vertical
            self.stackView.spacing = 5
            self.stackView.alignment = .fill
            self.floatingLabel.font = .pretendard(size: 12, weight: .medium)
            self.textFieldContainer.layer.borderColor = UIColor.gray800.cgColor
            self.textFieldContainer.backgroundColor = .clear
            self.textFieldContainer.layer.borderWidth = 1.5
        }
    }

    /// axis를 horizontal로 변경
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.isEmpty ?? true {
            UIView.animate(withDuration: 0.2) {
                self.stackView.axis = .horizontal
                self.stackView.spacing = 8
                self.stackView.alignment = .center
                self.floatingLabel.font = .pretendard(size: 16, weight: .medium)
                self.textFieldContainer.layer.borderWidth = 0
                self.textFieldContainer.backgroundColor = .gray50
            }
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension ReceiveInviteViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // Root view controller가 아닌 경우에만 스와이프 제스처 활성화
        let isRootViewController = navigationController.viewControllers.count <= 1
        navigationController.interactivePopGestureRecognizer?.isEnabled = !isRootViewController
    }
}
