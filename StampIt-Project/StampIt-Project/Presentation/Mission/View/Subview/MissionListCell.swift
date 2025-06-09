//
//  MissionListCell.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/5/25.
//

import UIKit
import SnapKit
import Then

final class MissionListCell: UITableViewCell {
    static let reuseIdentifier = "MissionListCell"
    
    private let label = UILabel().then {
        $0.numberOfLines = 0
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(label)
        
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setConstraints() {
        label.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    func configure(with text: String) {
        label.text = text
    }
}
