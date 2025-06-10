//
//  Profile.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import UIKit
import Then
import SnapKit
import Kingfisher

final class UserProfile: UIView {
    
    // MARK: - UI Components
    
    /// User Profile View
    private let vStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = MyPage.User.contentVSpacing
        $0.alignment = .center
    }
    
    private let profileImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .neutralGray300
        $0.layer.cornerRadius = MyPage.User.profileImageSize / 2
    }
    
    private let groupLable = UILabel().then {
        $0.font = .pretendard(size: MyPage.User.fontSizeSmall, weight: .medium)
        $0.textColor = .neutralGray500
        $0.text = "그룹이름"
    }
    
    private let hStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = MyPage.User.contentHSpacing
    }
    
    private let userLabel = UILabel().then {
        $0.font = .pretendard(size: MyPage.User.fontSizeMedium, weight: .bold)
        $0.textColor = ._000000
        $0.text = "유저이름"
    }
    
    private let editImageView = UIImageView().then {
        $0.image = UIImage(named: MyPage.User.editImage)
        $0.tintColor = .neutralGray400
    }
    
    /// Divider
    private let divider = UIView().then {
        $0.backgroundColor = .gray50
    }
    
    /// TableView
    let tableView = UITableView().then {
        $0.register(
            ProfileMenuCell.self,
            forCellReuseIdentifier: ProfileMenuCell.identifier
        )
        $0.register(
            MyPageHeader.self,
            forHeaderFooterViewReuseIdentifier: MyPageHeader.identifier
        )
        $0.allowsSelection = false
        $0.separatorStyle = .none
        $0.isScrollEnabled = false
    }
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            vStackView,
            divider,
            tableView
        ]
            .forEach { addSubview($0) }
        
        [
            profileImageView,
            groupLable,
            hStackView
        ]
            .forEach { vStackView.addArrangedSubview($0) }
        
        [
            userLabel,
            editImageView
        ]
            .forEach { hStackView.addArrangedSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        vStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(MyPage.User.top)
            $0.centerX.equalToSuperview()
        }
        
        profileImageView.snp.makeConstraints {
            $0.size.equalTo(MyPage.User.profileImageSize)
        }
        
        editImageView.snp.makeConstraints {
            $0.size.equalTo(MyPage.User.editImageSize)
        }
        
        divider.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview()
            $0.top.equalTo(vStackView.snp.bottom).offset(20)
            $0.height.equalTo(8)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(divider.snp.bottom)
            $0.directionalHorizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Methods
    
    func setUser(_ user: User) {
        guard let urlString = user.profileImageURL,
              let url = URL(string: urlString) else { return }
        profileImageView.kf.setImage(with: url)
        groupLable.text = user.groupName
        userLabel.text = user.nickname
    }
}
