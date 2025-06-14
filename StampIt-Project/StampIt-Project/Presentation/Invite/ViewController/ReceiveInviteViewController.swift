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

    private let viewModel = ReceiveInviteViewModel()
    private let disposeBag = DisposeBag()

    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "MascotCharacterGroup")
        $0.contentMode = .scaleAspectFit
    }

    private let helpLabel = UILabel().then {
        $0.text = "초대 받을 그룹의 코드를 입력해주세요"
        $0.textAlignment = .center
        $0.font = .pretendard(size: 14, weight: .medium)
        $0.textColor = .gray800
    }

    private let floatingLabel = UILabel().then {
        $0.text = "초대 코드"
        $0.font = .pretendard(size: 16, weight: .black)
        $0.textColor = .gray300
        $0.numberOfLines = 1
    }

    private let textField = UITextField().then {
        $0.placeholder = "코드를 입력하세요"
        $0.font = .pretendard(size: 16, weight: .medium)
        $0.borderStyle = .none
        $0.backgroundColor = .clear
        $0.autocorrectionType = .no
        $0.autocapitalizationType = .none
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
    }

    private let enterButton = DefaultButton(type: .enter)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        bindViewModel()
        textField.delegate = self
    }

    private func setupLayout() {
        view.addSubview(textFieldContainer)
        textFieldContainer.addSubview(stackView)
        [floatingLabel, textField]
        .forEach { stackView.addArrangedSubview($0) }

        [imageView, helpLabel, enterButton]
        .forEach { view.addSubview($0) }

        imageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(120)
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

        floatingLabel.snp.makeConstraints {
            $0.width.equalTo(100)
        }

        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(12)
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
    }
}

// UITextFieldDelegate
extension ReceiveInviteViewController: UITextFieldDelegate {

    /// axis를 vertical로 변경
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            self.stackView.axis = .vertical
            self.stackView.alignment = .leading
            self.floatingLabel.font = .pretendard(size: 12, weight: .medium)
            self.floatingLabel.textColor = .gray300
            self.textFieldContainer.layer.borderColor = UIColor.gray800.cgColor
            self.textFieldContainer.backgroundColor = .clear
            self.textFieldContainer.layer.borderWidth = 1.5
            self.view.layoutIfNeeded()
        }
    }

    /// axis를 horizontal로 변경
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.isEmpty ?? true {
            UIView.animate(withDuration: 0.2) {
                self.stackView.axis = .horizontal
                self.stackView.alignment = .center
                self.stackView.spacing = 20
                self.floatingLabel.font = .pretendard(size: 16, weight: .medium)
                self.floatingLabel.textColor = .gray300
                self.textFieldContainer.layer.borderColor = .none
                self.textFieldContainer.backgroundColor = .gray50
                self.textFieldContainer.layer.borderWidth = 0
                self.view.layoutIfNeeded()
            }
        }
    }
}
