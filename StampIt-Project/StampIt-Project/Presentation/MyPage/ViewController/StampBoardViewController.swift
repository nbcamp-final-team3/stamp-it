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

final class StampBoardViewController: UIViewController {
    
    // MARK: - Properties
    
    private var viewModel: StampBoardViewModel
    private var container: DIContainer
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components

    private let stampBoardView = StampBoardTab()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(
        viewModel: StampBoardViewModel,
        container: DIContainer
    ) {
        self.viewModel = viewModel
        self.container = container
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
            viewModel.state.stickerSummary,
            viewModel.state.stickersByPage
        )
        .observe(on: MainScheduler.instance)
        .bind(with: self) { owner, combined in
            let (summary, stickers) = combined
            owner.updateSnapshot(summary: summary, stickers: stickers)
            
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
        stickers: [[Sticker]]
    ) {
        let maxPage = stickers.count
        
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
                stickers[index].map { .sticker($0) },
                toSection: .page
            )
        }
        
        stampBoardView.stickerBoardDataSource.apply(snapshot, animatingDifferences: false)
        
        stampBoardView.getCollectionView().layoutIfNeeded()
    }
}

extension StampBoardViewController: StampBoardScrollDelegate {
    func didScrollToPage(_ page: Int) {
        /// 배경색 변경
        stampBoardView.backgroundColor = StampBoard(rawValue: page)?.bgColor
        stampBoardView.updateFooterPage(to: page)
    }
}

extension StampBoardViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentPage = viewModel.state.stickerSummary.value.completed
        let stickers: [[Sticker]] = viewModel.state.stickersByPage.value
        let clickedSticker = viewModel.state.stickersByPage.value[currentPage][indexPath.item]
        let missionId = clickedSticker.missionId
        
        
        print("didSelectItemAt stickers: \(stickers)")
        print("currentPage: \(currentPage)")
        print("indexPath.item: \(indexPath.item)")
        
        print("Clicked: \(viewModel.state.stickersByPage.value[stickers.count - 1][indexPath.item])")

        /// 뷰를 위해 생성된 Empty Stamp 는 모달창 띄우지 않음
        if clickedSticker.type != .stampGray {
            let viewModel = container.makeStampInfoViewModel()
            
            let stampInfoVC = StampInfoViewController(viewModel: viewModel)
            stampInfoVC.modalPresentationStyle = .overCurrentContext
            
            viewModel.action.accept(.load(missionId: missionId))
            
            self.present(stampInfoVC, animated: true)
        }
    }
}
