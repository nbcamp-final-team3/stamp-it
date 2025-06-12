//
//  MenuCell.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import UIKit
import Then
import SnapKit

final class ProfileMenuCell: UITableViewCell {
    
    // MARK: - Properties
    
    static let identifier = "ProfileMenuCell"
    
    // MARK: - UI Components
    
    private let titleLabel = UILabel().then {
        $0.font = .pretendard(size: MyPage.Menu.fontSizeMedium, weight: .regular)
        $0.textColor = ._000000
    }
    
    private let descriptionLabel = UILabel().then {
        $0.font = .pretendard(size: MyPage.Menu.fontSizeSmall, weight: .medium)
        $0.textColor = ._777777
    }
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setHierarchy()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            titleLabel,
            descriptionLabel
        ]
            .forEach { addSubview($0) }
    }
    
    // MARK: - Layout Helper
    
    private func setLayout() {
        titleLabel.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview()
            $0.top.equalToSuperview()
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(5)
        }
    }
    
    func setLayoutForOnlyTitle() {
        titleLabel.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-5)
        }
    }
    
    // MARK: - Methods
    
    func configureLabels(title: String, description: String) {
        titleLabel.text = title
        descriptionLabel.text = description
    }
}
