//
//  CustomToastView.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import UIKit
import SnapKit
import Then

final class ToastView: UIView {

    private let iconImageView = UIImageView().then {
        $0.image = UIImage(named: "CheckCircleColored")
        $0.tintColor = UIColor(.red400)
    }

    private let messageLabel = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .semibold)
        $0.textColor = .gray800
    }

    // MARK: - Init
    init(message: String = "") {
        super.init(frame: .zero)
        messageLabel.text = message
        setupView()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .FFFFFF
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = UIColor.red400.cgColor

    }

    private func setupLayout() {

        [iconImageView, messageLabel]
            .forEach { addSubview($0) }

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }

        messageLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(6)
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
    }

    // MARK: - Show Toast
    func show(in view: UIView, duration: TimeInterval = 2.0) {
        //이미 띄어진 경우 방지
        if self.superview != nil { return }
        view.addSubview(self)
        self.alpha = 0

        self.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(40)
            $0.height.equalTo(44)
        }

        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                self.alpha = 0
            }, completion: { _ in
                self.removeFromSuperview()
            })
        }
    }
}
