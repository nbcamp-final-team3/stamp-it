//
//  CustomToastView.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/17/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class ToastView: UIView {

    let didTapCancelButton = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    private let iconImageView = UIImageView().then {
        $0.image = UIImage(named: "CheckCircleColored")
        $0.tintColor = UIColor(.red400)
    }

    private let contentStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 12
    }

    private let messageLabel = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .semibold)
        $0.textColor = .gray800
    }

    private let cancelButton = UIButton().then {
        var config = UIButton.Configuration.plain()

        let attributed = AttributedString("취소하기")
        var container = AttributeContainer()
        container.font = .pretendard(size: 12, weight: .medium)
        container.foregroundColor = .red400

        let styled = attributed.settingAttributes(container)
        config.attributedTitle = styled
        config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

        $0.configuration = config
    }

    // MARK: - Init
    init(message: String = "", withCancelButton show: Bool = false) { // TODO: 버튼 타이틀도 지정할 수 있게 변경하기
        super.init(frame: .zero)
        messageLabel.text = message
        cancelButton.isHidden = !show
        setupView()
        setupLayout()
        bind()
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

        [iconImageView, contentStackView]
            .forEach { addSubview($0) }

        [messageLabel, cancelButton]
            .forEach { contentStackView.addArrangedSubview($0) }

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }

        contentStackView.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(6)
            $0.trailing.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
        }
    }

    func bind() {
        cancelButton.rx.tap
            .bind(to: didTapCancelButton)
            .disposed(by: disposeBag)
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
            $0.height.equalTo(44) // TODO: Figma 수치와 다름
        }

        UIView.animate(
          withDuration: 0.3,
          delay: 0,
          animations: { self.alpha = 1 }
        )

        dismiss(duration: duration)
    }

    func dismiss(duration: TimeInterval) {
        // 버튼 탭 이벤트 처리를 위해 main 스레드에서 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            UIView.animate(
              withDuration: 0.3,
              delay: 0,
              animations: { self.alpha = 0 },
              completion: { _ in self.removeFromSuperview() }
            )
        }
    }
}
