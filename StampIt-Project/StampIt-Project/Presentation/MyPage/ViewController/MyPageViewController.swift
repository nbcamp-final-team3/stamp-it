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
    private var stampBoardDataSource: UICollectionViewDiffableDataSource<StampBoardSection, StampBoardItem>!
    
    // MARK: - UI Components

    private let tabButton = TabButton()
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
        
        tabButton.stampTapped
            .bind(with: self) { owner, _ in
                owner.viewModel.action.accept(.tabButtonTapped(.stampBoard))
            }.disposed(by: disposeBag)
        
        tabButton.profileTapped
            .bind(with: self) { owner, _ in
                owner.viewModel.action.accept(.tabButtonTapped(.profile))
            }.disposed(by: disposeBag)
    
        viewModel.state.tabType
            .bind(with: self) { owner, tab in
                owner.tabButton.updateTitleColor(selected: tab)
                owner.updateSelectedTab(selected: tab)
            }.disposed(by: disposeBag)
        
        viewModel.state.stickers
            .bind(with: self) { owner, stickers in
                self.updateUI(with: stickers)
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
        stampBoardDataSource = UICollectionViewDiffableDataSource(
            collectionView: stampBoardView.getStampBoardView(),
            cellProvider: { collectionView, indexPath, itemIdentifier in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: StampCell.identifier,
                    for: indexPath
                ) as! StampCell
                
                let backgroundBoard = StampBoardSection.defaultBoard.type.flatMap { $0 }
                if backgroundBoard.indices.contains(indexPath.item) {
                    cell.configureDashedLine(with: backgroundBoard[indexPath.item])
                }
                cell.configureStamp(with: itemIdentifier)
                return cell
            })
        stampBoardView.setCollectionViewDataSource(stampBoardDataSource)

        profileView.tableView.dataSource = self
    }

    // MARK: - Snapshot
    
    private func updateUI(with item: [Sticker]) {
        let allStamps = makeAllStamps(with: item)
        var snapshot = NSDiffableDataSourceSnapshot<StampBoardSection, StampBoardItem>()
        snapshot.appendSections([.defaultBoard])
        snapshot.appendItems(allStamps, toSection: .defaultBoard)
        stampBoardDataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func makeAllStamps(with item: [Sticker]) -> [Sticker] {
        let redItems = Array(repeating: StickerType.stampRed, count: item.count)
        let grayItems = Array(repeating: StickerType.stampGray, count: 30 - item.count)
        return (redItems + grayItems).map {
            Sticker(stickerID: "\(UUID())", title: "", description: "", imageURL: "", type: $0, createdAt: Date())
        }
    }
    
//    private func zigzagOrder
    
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
