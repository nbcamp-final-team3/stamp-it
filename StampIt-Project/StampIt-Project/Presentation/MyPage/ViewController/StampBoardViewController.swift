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
        setStyle()
        setHierarchy()
        setLayout()
        setDelegate()
        setDataSource()
        bind()
    }
    
    // MARK: - Bind
    
    private func bind() {
        Observable.combineLatest(
            viewModel.state.stickerSummary,
            viewModel.state.stickers
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
        stickers: [Sticker]
    ) {
        var snapshot = NSDiffableDataSourceSnapshot<StampBoardSection, StampBoardItem>()
        snapshot.appendSections([.summary])
        snapshot.appendItems(
            [.summary(
                collected: summary.collected,
                completed: summary.completed
            )],
            toSection: .summary
        )
        
        snapshot.appendSections([.defaultBoard])
        snapshot.appendItems(
            stickers.map { .stickers($0) } ,
            toSection: .defaultBoard
        )
        stampBoardView.stickerBoardDataSource.apply(snapshot, animatingDifferences: false)
    }
}
