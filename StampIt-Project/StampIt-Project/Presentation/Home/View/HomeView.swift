//
//  HomeView.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit

final class HomeView: UIView {

    // MARK: - UI Components

    private let groupOrganizationView = GroupOrganizationView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setHierarchy()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Set Hierarchy

    private func setHierarchy() {
        addSubview(groupOrganizationView)
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        groupOrganizationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
