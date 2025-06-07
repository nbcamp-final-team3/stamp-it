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
import Toast

class SendInviteViewController: UIViewController {

    private let viewModel = SendInviteViewModel()
    private let disposeBag = DisposeBag()

    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "SendInvitingPageImage")
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    private let helpLabel = UILabel().then {
        $0.text = "초대할 멤버에게 아래 코드를 전달해주세요"
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 16)
    }

    private let textFiledInTitle = UILabel().then {
        $0.text = "초대코드"
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .darkGray
    }

    private let inviteCodeLabel = UILabel().then {
        $0.font = .boldSystemFont(ofSize: 18)
        $0.text = "abc123qwe"
        $0.textColor = .black
    }

    private let copyButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        $0.tintColor = .systemGray
    }

    private let inviteCodeStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 8
        $0.alignment = .center
        $0.distribution = .equalSpacing
        $0.backgroundColor = .inviteCodeBackground
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        bindViewModel()
    }

    private func setupLayout() {

        [imageView, helpLabel, inviteCodeStackView]
            .forEach{ view.addSubview($0) }

        [textFiledInTitle, inviteCodeLabel, copyButton]
            .forEach { inviteCodeStackView.addArrangedSubview($0) }

        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(40)
        }

        helpLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(imageView.snp.bottom).offset(20)
        }

        inviteCodeStackView.snp.makeConstraints {
            $0.top.equalTo(helpLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(40)
            $0.height.equalTo(50)
        }

        copyButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }

    }

    private func bindViewModel() {
        viewModel.state.inviteCode
            .bind(to: inviteCodeLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.state.showCopyMessage
            .subscribe(onNext: { [weak self] message in
                /// toast 색상설정을 위한 변수
                var style = ToastStyle()
                style.backgroundColor = .toastGray

                self?.view.makeToast(message, duration: 1.5, position: .bottom, image: nil, style: style
                , completion: nil)
            }).disposed(by: disposeBag)

        copyButton.rx.tap
            .map{SendInviteViewModel.Action.copyButtonTapped }
            .bind(to: viewModel.action)
            .disposed(by: disposeBag)
    }

}
