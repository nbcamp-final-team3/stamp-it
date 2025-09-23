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
    let didTapMissionCompleteButton = PublishRelay<HomeItem>()
    let didTapMoreMyMissionButton = PublishRelay<Void>()
    let didTapMoreMemberMissionButton = PublishRelay<Void>()
    let didTapRequestMissionButton = PublishRelay<Void>()
    let didTapSendMissoinButton = PublishRelay<Void>()
    let isSelectedRequestMissionButton = BehaviorRelay<Bool?>(value: nil)
    let selectMember = PublishRelay<Int>()
    let username = PublishRelay<String>()
    let groupName = PublishRelay<String>()

    // MARK: - Properties

    private let disposeBag = DisposeBag()

    // MARK: - UI Components

    private let groupOrganizationView = GroupOrganizationView().then {
        $0.isHidden = true
    }

    private let groupDashboardView = GroupDashboardView().then {
        $0.isHidden = true
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
            make.top.equalTo(safeAreaLayoutGuide)
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

        groupDashboardView.didTapMissionCompleteButton
            .bind(to: didTapMissionCompleteButton)
            .disposed(by: disposeBag)

        groupDashboardView.didTapMoreMyMissionButton
            .bind(to: didTapMoreMyMissionButton)
            .disposed(by: disposeBag)

        groupDashboardView.didTapMoreMemberMissionButton
            .bind(to: didTapMoreMemberMissionButton)
            .disposed(by: disposeBag)

        groupDashboardView.selectMember
            .bind(to: selectMember)
            .disposed(by: disposeBag)

        groupDashboardView.didTapRequestMissionButton
            .bind(to: didTapRequestMissionButton)
            .disposed(by: disposeBag)

        isSelectedRequestMissionButton
            .bind(to: groupDashboardView.isSelectedRequestMissionButton)
            .disposed(by: disposeBag)

        groupDashboardView.didTapSendMissionButton
            .bind(to: didTapSendMissoinButton)
            .disposed(by: disposeBag)

        username
            .bind(to: groupDashboardView.username)
            .disposed(by: disposeBag)

        groupName
            .bind(to: groupDashboardView.groupName)
            .disposed(by: disposeBag)
    }

    // MARK: - Methods

    func updateSnapshot(withItems items: [HomeItem], toSection section: HomeSection) {
        groupDashboardView.updateSnapshot(withItems: items, toSection: section)
    }

    func toggleView(showGroupOrganizationView: Bool) {
        groupOrganizationView.isHidden = !showGroupOrganizationView
        groupDashboardView.isHidden = showGroupOrganizationView
    }

    func setDefaultSelection() {
        groupDashboardView.setDefaultSelection()
    }
}
