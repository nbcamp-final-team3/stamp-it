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

final class StampBoardViewController: UIViewController {
    
    // MARK: - Properties
    
    private var viewModel: StampBoardViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components

    private let stampBoardView = StampBoardTab()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(viewModel: StampBoardViewModel) {
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
        setDataSource()
        bind()
    }
    
    // TODO: fetchStickerCount addSnapshotListener 적용후 삭제 후, 테스트
    // 화면이 나타날 때마다 데이터 새로고침
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.action.accept(.viewDidLoad)
    }
    
    // MARK: - Bind
    
    private func bind() {
        Observable.combineLatest(
            viewModel.state.stickerSummary,
            viewModel.state.stickersByPage
        )
        .bind(with: self) { owner, combined in
            let (summary, stickers) = combined
            owner.updateSnapshot(summary: summary, stickers: stickers)
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
            $0.edges.equalToSuperview()
        }
    }
    
    // MARK: - Delegate Helper
    
    private func setDelegate() {
    }

    // MARK: - DataSource Helper
    
    private func setDataSource() {
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
    }
}

extension StampBoardViewController: UICollectionViewDelegate {
    
    /// 스크롤이 멈췄을 때
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x
        let page = Int(round(offset / scrollView.frame.width))

        // 예: 상위 뷰 색상 바꾸기
        self.view.backgroundColor = .red // 최상위 VC
        stampBoardView.backgroundColor = StampBoard(rawValue: page)?.bgColor
    }
}
