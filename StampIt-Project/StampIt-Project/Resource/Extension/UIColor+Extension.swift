//
//  UIColor+Extension.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/7/25.
//

import Toast
import UIKit

//MARK: - UIColor Helper
extension UIColor {
    /// UIColor 생성기
    static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
        return UIColor(
            red: red / 255.0,
            green: green / 255.0,
            blue: blue / 255.0,
            alpha: alpha
        )
    }

    /// 토스트되는 알림의 기준 색
    static let toastGray = UIColor.rgb(204, 204, 204)
    /// 초대코드 배경화면 색
    static let inviteCodeBackground = UIColor.rgb(242, 242, 242)
}
