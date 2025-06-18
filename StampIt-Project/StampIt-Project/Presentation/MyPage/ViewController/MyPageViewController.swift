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
    
    private var viewModel: MyPageViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components

    private let navigationBar = DefaultNavigationBar(
        .segmentedControlTabs(
            tab1: TabType.stampBoard.title,
            tab2: TabType.profile.title
        ))
    private let stampBoardView = StampBoardTab()
    private let profileView = ProfileTab()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(viewModel: MyPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        viewModel.action.accept(.viewDidLoad)
        
        navigationBar.tabTapped
            .bind(with: self) { owner, type in
                owner.viewModel.action.accept(
                    .tabButtonTapped(TabType(rawValue: type.rawValue)!)
                )
            }.disposed(by: disposeBag)
    
        viewModel.state.tabType
            .bind(with: self) { owner, tab in
                owner.navigationBar.updateTabTitleColor(selected: tab)
                owner.updateSelectedTab(selected: tab)
            }.disposed(by: disposeBag)
        
        viewModel.state.stickers
            .bind(with: self) { owner, stickers in
                owner.updateUI(with: stickers)
            }.disposed(by: disposeBag)
        
        viewModel.state.stickerSummary
            .bind(with: self) { owner, summary in
                owner.stampBoardView.stickerSummary.accept(summary)
            }.disposed(by: disposeBag)
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        view.backgroundColor = .white
        stampBoardView.isHidden = false
        profileView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            navigationBar,
            stampBoardView,
            profileView,
        ]
            .forEach { view.addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
        }
        
        stampBoardView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.directionalHorizontalEdges.bottom.equalToSuperview()
        }
        
        profileView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
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

    // MARK: - Snapshot
    
    private func updateUI(with stickers: [Sticker]) {
        var snapshot = NSDiffableDataSourceSnapshot<StampBoardSection, StampBoardItem>()
        snapshot.appendSections([.defaultBoard])
        snapshot.appendItems(stickers, toSection: .defaultBoard)
        stampBoardView.stickerBoardDataSource.apply(snapshot, animatingDifferences: false)
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
