//
//  NoResultsView.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/12/25.
//

import UIKit
import SnapKit
import Then
import RxSwift
import RxCocoa

final class NoResultsView: UIView {

    let didTapSendMissionButton = PublishRelay<Void>()
    private let disposeBag = DisposeBag()

    private let containerStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 20
        $0.alignment = .center
    }

    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "MascotCharacterSadGray")
        $0.contentMode = .scaleAspectFit
    }

    private let labelStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .center
    }

    private let titleLabel = UILabel().then {
        $0.font = .pretendard(size: 16, weight: .bold)
        $0.textColor = .gray600
    }
    
    private let descriptionLabel = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .gray300
    }

    private let sendMissionButton = UIButton().then {
        var config = UIButton.Configuration.filled()

        // attributedTitle
        let attributed = AttributedString("미션 전달하기")
        var container = AttributeContainer()
        container.font = UIFont.pretendard(size: 14, weight: .semibold)
        let styled = attributed.settingAttributes(container)
        config.attributedTitle = styled

        // color
        config.baseBackgroundColor = .red400
        config.baseForegroundColor = .white

        config.contentInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)

        $0.configuration = config
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        [containerStackView].forEach { addSubview($0) }

        [
            imageView,
            labelStackView,
            sendMissionButton,
        ].forEach { containerStackView.addArrangedSubview($0) }

        [
            titleLabel,
            descriptionLabel,
        ].forEach { labelStackView.addArrangedSubview($0) }

        setConstraints()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setConstraints() {
        containerStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        imageView.snp.makeConstraints {
            $0.width.equalTo(80)
            $0.height.equalTo(100)
        }
        
        titleLabel.snp.makeConstraints {
            $0.height.equalTo(19)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.height.equalTo(21)
        }
    }

    private func bind() {
        sendMissionButton.rx.tap
            .bind(to: didTapSendMissionButton)
            .disposed(by: disposeBag)
    }

    func configureContent(title: String, description: String? = nil, withButton: Bool = false) {
        titleLabel.text = title
        descriptionLabel.text = description
        descriptionLabel.isHidden = description == nil
        sendMissionButton.isHidden = !withButton
    }

    func updateContainerTopInset(_ inset: CGFloat) {
        containerStackView.snp.remakeConstraints {
            $0.top.equalToSuperview().inset(inset)
            $0.centerX.equalToSuperview()
        }
    }
}
