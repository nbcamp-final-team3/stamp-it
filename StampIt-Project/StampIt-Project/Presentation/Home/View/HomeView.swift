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

    private let groupOrganizationView = GroupOrganizationView().then {
        $0.isHidden = true
    }

    private let groupDashboardView = GroupDashboardView().then {
        $0.isHidden = false
    }

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
        [
            groupOrganizationView,
            groupDashboardView,
        ].forEach { addSubview($0) }
    }

    // MARK: - Set Constraints

    private func setConstraints() {
        groupOrganizationView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(16)
            make.directionalHorizontalEdges.bottom.equalToSuperview()
        }

        groupDashboardView.snp.makeConstraints { make in
            make.verticalEdges.equalTo(safeAreaLayoutGuide)
            make.directionalHorizontalEdges.equalToSuperview()
        }
    }

    // MARK: - Bind

    private func bind() {
        groupOrganizationView.didTapGroupOrganizationButton
            .bind(to: didTapGroupOrganizationButton)
            .disposed(by: disposeBag)
    }

    func updateSnapshot(withItems items: [HomeItem], toSection section: HomeSection) {
        groupDashboardView.updateSnapshot(withItems: items, toSection: section)
    }
}
