//
//  TabButton.swift
//  StampIt-Project
//
//  Created by kingj on 6/9/25.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

enum TabType {
    case stampBoard
    case profile
}

final class TabButton: UIView {
    
    // MARK: - UI Components
    
    private let stackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = MyPage.Tab.textSpacing
    }
    
    private let stampButton = UIButton(type: .system).then {
        $0.setTitle(MyPage.Tab.stamp, for: .normal)
        $0.titleLabel?.font = .pretendard(size: MyPage.Tab.fontSize, weight: .medium)
    }
    
    private let profileButton = UIButton(type: .system).then {
        $0.setTitle(MyPage.Tab.profile, for: .normal)
        $0.titleLabel?.font = .pretendard(size: MyPage.Tab.fontSize, weight: .medium)
    }
    
    var stampTapped: Observable<Void> {
        stampButton.rx.tap.asObservable()
    }

    var profileTapped: Observable<Void> {
        profileButton.rx.tap.asObservable()
    }
    
    // MARK: - Initializer, Deinit, requiered
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setStyle()
        setHierarchy()
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        stampButton.setTitleColor(.neutralGray900, for: .normal)
        profileButton.setTitleColor(.neutralGray300, for: .normal)
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            stackView
        ]
            .forEach { addSubview($0) }
        
        [
            stampButton,
            profileButton,
        ]
            .forEach { stackView.addArrangedSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        stackView.snp.makeConstraints {
            $0.leading.directionalVerticalEdges.equalToSuperview().inset(MyPage.Tab.leading)
        }
    }
    
    // MARK: - Methods
    
    func updateTitleColor(selected: TabType) {
        switch selected {
        case .stampBoard:
            stampButton.setTitleColor(.neutralGray900, for: .normal)
            profileButton.setTitleColor(.neutralGray300, for: .normal)
            
        case .profile:
            stampButton.setTitleColor(.neutralGray300, for: .normal)
            profileButton.setTitleColor(.neutralGray900, for: .normal)
        }
    }
}
