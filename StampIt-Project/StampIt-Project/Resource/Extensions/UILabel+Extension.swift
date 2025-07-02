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
        // 1) 문단 스타일
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.alignment = self.textAlignment
        style.lineBreakMode = self.lineBreakMode

        // 2) baselineOffset 계산 (lineHeight 과 실제 폰트 높이 차이의 절반)
        let offset = (lineHeight - font.lineHeight) / 2

        // 3) 속성 딕셔너리
        let attrs: [NSAttributedString.Key: Any] = [
            .paragraphStyle: style,
            .baselineOffset: offset
        ]

        // 4) 적용
        attributedText = NSAttributedString(
            string: text ?? "내용 없음",
            attributes: attrs
        )
    }
}
