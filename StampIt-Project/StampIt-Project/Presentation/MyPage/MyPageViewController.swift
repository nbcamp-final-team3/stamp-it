//
//  MyPageViewController.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import UIKit
import Then
import SnapKit
import RxSwift

final class MyPageViewController: UIViewController {
    
    
    // MARK: - Properties
    
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components

    private let tabButton = TabButton()
    private let stampBoardView = StampBoard()
    private let profileView = UserProfile()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setStyle()
        setHierarchy()
        setLayout()
        setDelegate()
        setDataSource()
        bind()
    }
    
    // MARK: - Bind
    
    private func bind() {
        tabButton.stampTapped
            .bind { [weak self] in
                guard let self else { return }
                tabButton.updateTitleColor(selected: .stampBoard)
                updateSelectedTab(selected: .stampBoard)
            }.disposed(by: disposeBag)
        
        tabButton.profileTapped
            .bind { [weak self] in
                guard let self else { return }
                tabButton.updateTitleColor(selected: .profile)
                updateSelectedTab(selected: .profile)
            }.disposed(by: disposeBag)
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        view.backgroundColor = .white
        stampBoardView.isHidden = false
        profileView.isHidden = true
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            tabButton,
            stampBoardView,
            profileView,
        ]
            .forEach { view.addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        tabButton.snp.makeConstraints {
            $0.top.directionalHorizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        stampBoardView.snp.makeConstraints {
            $0.top.equalTo(tabButton.snp.bottom)
            $0.directionalHorizontalEdges.bottom.equalToSuperview()
        }
        
        profileView.snp.makeConstraints {
            $0.top.equalTo(tabButton.snp.bottom)
            $0.directionalHorizontalEdges.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Delegate Helper
    private func setDelegate() {
        profileView.tableView.delegate = self
    }

    // MARK: - DataSource Helper
    private func setDataSource() {
        profileView.tableView.dataSource = self
    }
    
    // MARK: - Methods
    
    private func updateSelectedTab(selected: TabType) {
        switch selected {
        case .stampBoard:
            stampBoardView.isHidden = false
            profileView.isHidden = true
            
        case .profile:
            stampBoardView.isHidden = true
            profileView.isHidden = false
        }
    }
}

extension MyPageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        MyPage.TableView.sectionHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = MyPageProfileSection.allCases[section]
        let title = section.headerTitle
        
        let header = MyPageHeaderView()
        header.configureLabel(with: title)
        if section == .groupMember {
            header.isDividerHidden(true)
        }
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        MyPage.TableView.cellHeight
    }
}

extension MyPageViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        MyPageProfileSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = MyPageProfileSection.allCases[section]
        return section.menus.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ProfileMenuCell.identifier,
            for: indexPath
        ) as! ProfileMenuCell
        
        let section = MyPageProfileSection.allCases[indexPath.section]
        let menu = section.menus[indexPath.item]
        
        if section == .groupMember {
            if indexPath.item == .zero {
                cell.setLayoutForOnlyTitle()
            }
        }
        
        cell.configureLabels(title: menu.title, description: menu.subtitle)
        return cell
    }
}
