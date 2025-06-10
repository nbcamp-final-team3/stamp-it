//
//  HomeView.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/9/25.
//

import UIKit
import RxSwift
import RxRelay

final class HomeView: UIView {

    // MARK: - Actions

    let didTapGroupOrganizationButton = PublishRelay<Void>()

    // MARK: - Properties

    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let groupOrganizationView = GroupOrganizationView()
    private let groupDashboardView = GroupDashboardView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setHierarchy()
        setConstraints()
        bind()
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

    // MARK: - Bind

    private func bind() {
        groupOrganizationView.didTapGroupOrganizationButton
            .bind(to: didTapGroupOrganizationButton)
            .disposed(by: disposeBag)
    }
}
