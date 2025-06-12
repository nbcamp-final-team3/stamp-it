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
    
//    private var viewModel = MyPageViewModel(useCase: MyPageUseCase())
    
    private var stampBoardDataSource: UICollectionViewDiffableDataSource<StampBoardSection, StampBoardItem>!
    
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components

    private let tabButton = TabButton()
    private let stampBoardView = StampBoardTab()
    private let profileView = ProfileTab()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setStyle()
        setHierarchy()
        setLayout()
        setDelegate()
        setDataSource()
        bind()
        updateUI(item: MyPageViewModel.stamps)
    }
    
    // MARK: - Bind
    
    private func bind() {
        // TODO: VM 에서 tabButton 상태관리
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
    
    private func updateUI(item: [Sticker]) {
        let allStamps = makeAllStamps(item: item)
        var snapshot = NSDiffableDataSourceSnapshot<StampBoardSection, StampBoardItem>()
        snapshot.appendSections([.defaultBoard])
        snapshot.appendItems(allStamps, toSection: .defaultBoard)
//        snapshot.appendItems(item, toSection: .defaultBoard)
        stampBoardDataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func makeAllStamps(item: [Sticker]) -> [Sticker] {
        let redItems = Array(repeating: StickerType.stampRed, count: item.count)
        let grayItems = Array(repeating: StickerType.stampGray, count: 30 - item.count)
        return (redItems + grayItems).map {
            Sticker(stickerID: "0", title: "", description: "", imageURL: "", type: $0, createdAt: Date())
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
