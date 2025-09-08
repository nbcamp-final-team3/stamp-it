//
//  StampBoardTapViewController.swift
//  StampIt-Project
//
//  Created by kingj on 6/24/25.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxRelay

final class StampBoardViewController: BaseViewController {
    
    // MARK: - Properties
    
    private var viewModel: StampBoardViewModel
    private let disposeBag = DisposeBag()
    private var currentPage: Int = .zero
    
    override var screenName: String { "StampBoard" }
    
    // MARK: - UI Components

    private let stampBoardView = StampBoardTab()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(
        viewModel: StampBoardViewModel,
    ) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.action.accept(.viewDidLoad)
        setStyle()
        setHierarchy()
        setLayout()
        setDelegate()
        bind()
    }
    
    // MARK: - Bind
    
    private func bind() {
        Observable.combineLatest(
            viewModel.state.stampSummary,
            viewModel.state.stampsByPage
        )
        .observe(on: MainScheduler.instance)
        .bind(with: self) { owner, combined in
            let (summary, stamps) = combined
            owner.updateSnapshot(summary: summary, stamps: stamps)
            
            let page = summary.completed
            owner.stampBoardView.footerPageRelay.accept(
                page == .zero ? page : page + 1
            )
        }.disposed(by: disposeBag)
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            stampBoardView,
        ]
            .forEach { view.addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        stampBoardView.snp.makeConstraints {
            $0.top.directionalHorizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    // MARK: - Delegate Helper
    
    private func setDelegate() {
        stampBoardView.setScrollDelegate(self)
        stampBoardView.setCollectionViewDelegate(self)
    }
    
    // MARK: - Snapshot
    
    private func updateSnapshot(
        summary: (collected: Int, completed: Int),
        stamps: [[StampBoardStamp]]
    ) {
        let maxPage = stamps.count
        
        var snapshot = NSDiffableDataSourceSnapshot<StampBoardSection, StampBoardItem>()

        /// Item & Section For Summary Section
        let summaryItem: [StampBoardItem] = [
            .summary(
                collected: summary.collected,
                completed: summary.completed
            )
        ]
        snapshot.appendSections([.summary])
        snapshot.appendItems(summaryItem, toSection: .summary)
        
        snapshot.appendSections([.page])
        
        /// Item & Section For StampBoard
        for index in 0..<maxPage {
            snapshot.appendItems(
                stamps[index].map { .stamp($0) },
                toSection: .page
            )
        }
        
        stampBoardView.stampBoardDataSource.apply(snapshot, animatingDifferences: false)
        
        stampBoardView.getCollectionView().layoutIfNeeded()
    }
}

extension StampBoardViewController: StampBoardScrollDelegate {
    func didScrollToPage(_ page: Int) {
        currentPage = page
        
        /// 배경색 변경
        stampBoardView.backgroundColor = StampBoard(rawValue: page)?.background
        stampBoardView.updateFooterPage(to: page)
    }
}

extension StampBoardViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let cell = cell as? StampCell else { return }
        
        let stamps = viewModel.state.stampsByPage.value
        let itemIndexInPage = indexPath.item % Stamp.totalStamp

        guard stamps.indices.contains(currentPage),
              stamps[currentPage].indices.contains(itemIndexInPage) else {
            return
        }
        
        let stamp = stamps[currentPage][itemIndexInPage]

        let dashedType = StampBoardSection.page.type.flatMap { $0 }[stamp.zigzagIndex]
        
        cell.configureDashedLine(with: dashedType)
        
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let stampsByPage = viewModel.state.stampsByPage.value
        
        let itemIndexInPage = indexPath.item % Stamp.totalStamp
        
        let clickedStamp = stampsByPage[currentPage][itemIndexInPage]
        let missionId = clickedStamp.missionID

        /// Empty Stamp 는 모달뷰 띄우지 않음
        if clickedStamp.type != .gray {
            let viewModel = DIContainer.shared.makeStampInfoViewModel()

            let stampInfoVC = StampInfoViewController(viewModel: viewModel)
            stampInfoVC.modalPresentationStyle = .custom
            
            viewModel.action.accept(.load(missionId: missionId))
            
            self.present(stampInfoVC, animated: true)
        }
    }
}
