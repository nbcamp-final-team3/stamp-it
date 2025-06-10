//
//  HeaderView.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import UIKit
import Then
import SnapKit

final class ProfileHeader: UITableViewHeaderFooterView {
    
    // MARK: - Properties
    
    static let identifier = "MyPageHeaderView"
    
    var isDividerHidden: Bool = false {
        didSet {
            divider.isHidden = isDividerHidden
        }
    }
    
    // MARK: - UI Components
    
    private let divider = UIView().then {
        $0.backgroundColor = .gray50
    }
    
    private let titleLabel = UILabel().then {
        $0.font = .pretendard(size: MyPage.Menu.fontSizeSmall, weight: .semibold)
        $0.textColor = .neutralGray400
    }
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setStyle()
        setHierarchy()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        contentView.backgroundColor = .white
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            divider,
            titleLabel
        ]
            .forEach { addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        divider.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview()
            $0.height.equalTo(MyPage.Menu.dividerHeight)
            $0.top.equalToSuperview().offset(-10)
        }
        
        titleLabel.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview()
            $0.top.equalTo(divider.snp.bottom).offset(20)
        }
    }
    
    // MARK: - Methods
    
    func configureLabel(with text: String) {
        titleLabel.text = text
    }
}
