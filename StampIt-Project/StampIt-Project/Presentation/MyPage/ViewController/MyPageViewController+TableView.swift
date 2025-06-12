//
//  MyPageViewController+TableView.swift
//  StampIt-Project
//
//  Created by kingj on 6/11/25.
//

import UIKit

extension MyPageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        MyPage.TableView.sectionHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = MyPageProfileSection.allCases[section]
        let title = section.headerTitle
        
        let header = ProfileHeader()
        header.configureLabel(with: title)
        if section == .groupMember {
            header.isDividerHidden = true
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
