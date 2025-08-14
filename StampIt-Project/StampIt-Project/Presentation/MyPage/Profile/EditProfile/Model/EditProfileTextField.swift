//
//  EditProfileTextField.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/30/25.
//

import UIKit

final class EditProfileTextField: UITextField {
    // 텍스트필드 왼쪽/오른쪽 여백
    let textPadding = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
    // 클리어 버튼 여백
    let clearButtonPadding: CGFloat = 16
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textPadding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textPadding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: textPadding)
    }
    
    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        let original = super.clearButtonRect(forBounds: bounds)
        return original.offsetBy(dx: -clearButtonPadding, dy: 0)
    }
}
