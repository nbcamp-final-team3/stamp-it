//
//  UILabel+Extension.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit

extension UILabel {
    /// Label에 LineHeight 값을 설정하는 메서드
    ///
    /// text가 nil이면 line Height가 적용이 안되기 때문에, 초기화 시 입력할 text가 없는 경우 nil을 전달하면 "내용 없음"이 입력됩니다.
    func setTextWithLineHeight(text: String?, lineHeight: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.maximumLineHeight = lineHeight
        style.minimumLineHeight = lineHeight

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: style,
        ]

        let attrString = NSAttributedString(string: text ?? "내용 없음", attributes: attributes)
        self.attributedText = attrString
    }
}
