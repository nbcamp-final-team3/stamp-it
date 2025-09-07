//
//  SuggestionButton.swift
//  StampIt-Project
//
//  Created by 권순욱 on 9/6/25.
//

import UIKit

final class SuggestionButton: UIButton {
    private let suggestion: Suggestion
    
    init(suggestion: Suggestion) {
        self.suggestion = suggestion
        super.init(frame: .zero)
        
        var configuration = Configuration.plain()
        configuration.title = suggestion.title
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        configuration.baseForegroundColor = .gray200
        
        // 폰트 및 폰트 색상 설정
        let font = UIFont.pretendard(size: 14, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.gray400]
        let attributedTitle = NSAttributedString(string: configuration.title ?? "", attributes: attributes)
        configuration.attributedTitle = AttributedString(attributedTitle)
        
        // 아이콘 설정
        let icon = suggestion.source == .history ? UIImage(systemName: "clock.fill") : UIImage(systemName: "wand.and.sparkles")
        configuration.image = icon
        configuration.imagePadding = 8
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        
        self.configuration = configuration
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getSuggestion() -> Suggestion {
        suggestion
    }
}
