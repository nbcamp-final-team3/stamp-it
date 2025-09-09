//
//  MyPageViewController+TableView.swift
//  StampIt-Project
//
//  Created by kingj on 6/11/25.
//

import UIKit

extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = MyPageProfileSection.allCases[section]
        switch section {
        case .groupMember:
            return MyPage.TableView.headerHeightHigh
        case .groupService:
            return MyPage.TableView.headerHeightHigh
        }
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = MyPageProfileSection.allCases[indexPath.section]
        let menu = section.menus[indexPath.row]
        
        switch menu {
            // 스와이프 뒤로가기 제스처 활성화 (push 후에 활성화됨)
        case .MemberManage:
            let vc = DIContainer.shared.makeGroupMemberManageViewController()
            navigationController?.pushViewController(vc, animated: true)

        case .inviteMember:
            let vc = DIContainer.shared.makeSendInviteViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        case .receiveInvite:
            let vc = DIContainer.shared.makeReceiveInviteViewController()
            navigationController?.pushViewController(vc, animated: true)
            
        case .leaveGroup:
            leaveGroup()
        case .leaveService:
            deleteAccount()
        case .logout:
            logOut()
        }
    }
}

extension ProfileViewController: UITableViewDataSource {
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
        
//        if section == .groupMember {
//            if indexPath.item == .zero {
//                cell.setLayoutForOnlyTitle()
//            }
//        }
        
        cell.configureLabels(title: menu.title, description: menu.subtitle)
        return cell
    }
}
