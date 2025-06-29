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

    // MARK: - Constants
    private enum Constants {
        static let keyboardOffset: CGFloat = 40
        static let toastDelay: TimeInterval = 0.3
        static let animationDuration: TimeInterval = 0.2
        static let rootTransitionDuration: TimeInterval = 0.15
    }

    // MARK: - properties

    private let viewModel: ReceiveInviteViewModel
    private let disposeBag = DisposeBag()
    private var isKeyboardVisible = false

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
        $0.enablesReturnKeyAutomatically = true
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
        setupNavigation()
        setupKeyboardDismiss()
        setupKeyboardNotifications()
        textField.delegate = self

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
        bindTextField()
        bindEnterButton()
        bindNavigation()
        bindMessages()
        bindInviteCompletion()
    }
    
    private func bindTextField() {
        textField.rx.text.orEmpty
            .distinctUntilChanged()
            .map { ReceiveInviteViewModel.Action.codeChanged($0) }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)
    }
    
    private func bindEnterButton() {
        enterButton.rx.tap
            .map { ReceiveInviteViewModel.Action.enterButtonTapped }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)

        viewModel.state.isEnterButtonEnabled
            .bind(to: enterButton.rx.isEnabled)
            .disposed(by: disposeBag)
    }
    
    private func bindNavigation() {
        navigationBar.backTapped
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
    }
    
    private func bindMessages() {
        viewModel.state.showMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (type, message) in
                guard let self = self else { return }
                
                // 키보드가 올라와 있으면 먼저 내리기
                if self.isKeyboardVisible {
                    self.textField.resignFirstResponder()
                    
                    // 키보드가 완전히 내려간 후 토스트 표시
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.toastDelay) {
                        let toastView = ToastView()
                        toastView.show(in: self.view, message: message, type: type)
                    }
                } else {
                    // 키보드가 내려가 있으면 바로 토스트 표시
                    let toastView = ToastView()
                    toastView.show(in: self.view, message: message, type: type)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindInviteCompletion() {
        viewModel.state.didCompleteInvite
            .bind(with: self) { owner, _ in
                let container = DIContainer.shared

                // 홈 탭으로 전환
                let tabBarController = MainTabBarController(container: container)
                tabBarController.selectedIndex = 0

                WindowTransitionManager.shared.changeRootViewController(to: tabBarController, duration: Constants.rootTransitionDuration)
                // 현재 navigation stack에서 pop
                owner.navigationController?.popToRootViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.dismissKeyboard()
            })
            .disposed(by: disposeBag)
    }

    private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupKeyboardNotifications() {
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .subscribe(onNext: { [weak self] notification in
                self?.handleKeyboardWillShow(notification)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
            .subscribe(onNext: { [weak self] notification in
                self?.handleKeyboardWillHide(notification)
            })
            .disposed(by: disposeBag)
    }

    private func handleKeyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        isKeyboardVisible = true
        
        let keyboardTopY = keyboardFrame.minY
        let buttonBottomY = enterButton.frame.maxY
        
        // 버튼이 키보드에 가려지는 경우만 이동
        if buttonBottomY > keyboardTopY {
            let offset = buttonBottomY - keyboardTopY + Constants.keyboardOffset
            UIView.animate(withDuration: duration) {
                self.view.transform = CGAffineTransform(translationX: 0, y: -offset)
            }
        }
    }

    private func handleKeyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        isKeyboardVisible = false
        
        UIView.animate(withDuration: duration) {
            self.view.transform = .identity
        }
    }
}

// UITextFieldDelegate
extension ReceiveInviteViewController: UITextFieldDelegate {

    /// axis를 vertical로 변경
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: Constants.animationDuration) {
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
            UIView.animate(withDuration: Constants.animationDuration) {
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

extension ReceiveInviteViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // navigationController의 viewControllers가 2개 이상일 때만 pop 허용
        return navigationController?.viewControllers.count ?? 0 > 1
    }
}

