//
//  DefaultNavigationBar.swift
//  StampIt-Project
//
//  Created by kingj on 6/17/25.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxRelay

final class DefaultNavigationBar: UIView {
    
    // MARK: - Properties
    
    private let type: NavigationBarType
    
    let backTapped = PublishRelay<Void>()
    let tabTapped = PublishRelay<TabType>()
    
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    private let titleLabel = UILabel().then {
        $0.font = .pretendard(size: Navigation.fontSize, weight: .medium)
        $0.textColor = .neutralGray900
    }
    
    private let backButton = UIButton().then {
        $0.setImage(UIImage(named: Navigation.backButton), for: .normal)
    }
    
    private let logoImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
    }

    private lazy var tabButton1 = createTabButton()
    private lazy var tabButton2 = createTabButton()
    
    // MARK: - UI Components Maker
    
    private func createTabButton() -> UIButton {
        UIButton(type: .system).then {
            $0.titleLabel?.font = .pretendard(size: Navigation.fontSize, weight: .medium)
        }
    }
    
    // MARK: - Initializer, Deinit, requiered
    
    init(_ type: NavigationBarType) {
        self.type = type
        super.init(frame: .zero)
        applyNavigationBarStyle(type)
        setStyle()
        setHierarchy()
        setLayout()
        bind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bind() {
        backButton.rx.tap
            .bind(to: backTapped)
            .disposed(by: disposeBag)
        
        tabButton1.rx.tap
            .map { .stampBoard }
            .bind(to: tabTapped)
            .disposed(by: disposeBag)
        
        tabButton2.rx.tap
            .map { .profile }
            .bind(to: tabTapped)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        backgroundColor = .FFFFFF
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        switch type {
        case .plainTitle:
            [ titleLabel ].forEach { addSubview($0) }
        case .titleWithBackButton:
            [ titleLabel, backButton ].forEach { addSubview($0) }
        case .logoWithItem:
            [ logoImageView ].forEach { addSubview($0) }
        case .segmentedControlTabs:
            [ tabButton1, tabButton2 ].forEach { addSubview($0) }
        }
    }

    // MARK: - Layout Helper
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Navigation.height)
    }
    
    private func setLayout() {
        switch type {
        case .plainTitle:
            titleLabel.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.equalToSuperview().inset(Navigation.horizontal)
            }
        case .titleWithBackButton:
            backButton.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.equalToSuperview().inset(Navigation.horizontal)
                $0.size.equalTo(Navigation.buttonSize)
            }
            
            titleLabel.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.equalTo(backButton.snp.trailing).offset(Navigation.spacing)
            }
        case .logoWithItem:
            logoImageView.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.equalToSuperview().inset(Navigation.horizontal)
                $0.width.equalTo(Navigation.appLogoWidth)
                $0.height.equalTo(Navigation.appLogoHeight)
            }

        case .segmentedControlTabs:
            tabButton1.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.equalToSuperview().inset(Navigation.horizontal)
            }
            
            tabButton2.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.leading.equalTo(tabButton1.snp.trailing).offset(Navigation.spacing)
            }
        }
    }
    
    // MARK: - NavigationBar Type
    
    private func applyNavigationBarStyle(_ type: NavigationBarType) {
        switch type {
        case .plainTitle(let title):
            titleLabel.text = title
            
        case .titleWithBackButton(let title):
            titleLabel.text = title
            
        case .logoWithItem:
            logoImageView.image = UIImage(named: Navigation.appLogo)
            
        case .segmentedControlTabs(let tab1, let tab2):
            tabButton1.setTitle(tab1, for: .normal)
            tabButton1.setTitleColor(.neutralGray900, for: .normal)
            
            tabButton2.setTitle(tab2, for: .normal)
            tabButton2.setTitleColor(.neutralGray300, for: .normal)
        }
    }
    
    // MARK: - Methods
    
    func updateTabTitleColor(selected: TabType) {
        switch selected {
        case .stampBoard:
            tabButton1.setTitleColor(.neutralGray900, for: .normal)
            tabButton2.setTitleColor(.neutralGray300, for: .normal)
            
        case .profile:
            tabButton1.setTitleColor(.neutralGray300, for: .normal)
            tabButton2.setTitleColor(.neutralGray900, for: .normal)
        }
    }
    
    func updateNavigationTitle(_ title: String) {
        titleLabel.text = title
    }

    /// 네비바 오른쪽에 아이템 추가
    func addRightItem(_ item: UIView) {
        addSubview(item)

        item.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(Navigation.horizontal)
            $0.size.equalTo(Navigation.buttonSize)
        }
    }
}

extension DefaultNavigationBar {
    enum NavigationBarType {
        case plainTitle(title: String)
        case titleWithBackButton(title: String)
        case logoWithItem
        case segmentedControlTabs(tab1: String, tab2: String)
    }
}
