//
//  DefaultButton.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/7/25.
//

import UIKit

final class DefaultButton: UIButton {

    // MARK: - Properties

    var type: ButtonType

    // MARK: - Init

    init(type: ButtonType) {
        self.type = type
        super.init(frame: .zero)
        setStyles()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Set Styles

    private func setStyles() {
        setConfiguration(with: type)
        setCornerRadius()
        stateUpdateHandler()
    }

    /// Configuration 설정
    private func setConfiguration(with type: ButtonType) {
        var config = UIButton.Configuration.filled()

        // attributedTitle
        let attributed = AttributedString(type.title)
        var container = AttributeContainer()
        container.font = type.font
        let styled = attributed.settingAttributes(container)
        config.attributedTitle = styled

        // color
        config.baseBackgroundColor = .red400
        config.baseForegroundColor = .white

        config.contentInsets = type.contentInsets

        configuration = config
    }

    /// 버튼의 state가 변경될 때마다 호출되는 handler 정의
    private func stateUpdateHandler() {
        configurationUpdateHandler = { button in
            var updated = button.configuration
            updated?.baseBackgroundColor = button.isEnabled ? .red400 : .gray50
            updated?.baseForegroundColor = button.isEnabled ? .white : .gray300
            button.configuration = updated
        }
    }

    /// cornerRadius 처리
    ///
    /// Configuration 사용에 따라 masksToBounds로 layer 마스킹
    private func setCornerRadius() {
        layer.cornerRadius = type.radius
        layer.masksToBounds = true
    }

    /// 버튼 타입이 proceed일 때 마지막 단계인 경우 타이틀 변경
    func updateProceed(isFinalStep: Bool) {
        guard case .proceed(_) = type else { return }
        setConfiguration(with: .proceed(isFinalStep: isFinalStep))
    }
}

extension DefaultButton {
    enum ButtonType {
        case proceed(isFinalStep: Bool)
        case confirm
        case send
        case enter
        case modify
        case groupOrganization

        var title: String {
            switch self {
            case .proceed(let isFinalStep):
                isFinalStep ? "시작하기" : "다음"
            case .confirm:
                "확인"
            case .send:
                "전달하기"
            case .enter:
                "입장하기"
            case .modify:
                "수정하기"
            case .groupOrganization:
                "그룹 구성하기"
            }
        }

        var font: UIFont {
            switch self {
            case .groupOrganization:
                    .pretendard(size: 16, weight: .bold)
            default:
                    .pretendard(size: 18, weight: .semibold)
            }
        }

        var radius: CGFloat {
            switch self {
            case .groupOrganization: 8
            default: 12
            }
        }

        var contentInsets: NSDirectionalEdgeInsets {
            switch self {
            case .groupOrganization:
                    .init(top: 6, leading: 16, bottom: 6, trailing: 16)
            default:
                    .init(top: 16, leading: 20, bottom: 16, trailing: 20)
            }
        }
    }
}
