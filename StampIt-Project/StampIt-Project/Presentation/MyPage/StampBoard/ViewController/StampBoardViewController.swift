//
//  StampBoardTapViewController.swift
//  StampIt-Project
//
//  Created by kingj on 6/24/25.
//

import UIKit
import SnapKit
import RxSwift

final class StampBoardViewController: BaseViewController {
    
    // MARK: - Properties
    
    private var viewModel: StampBoardViewModel
    private let disposeBag = DisposeBag()

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
            let page = summary.completed

            let viewState = StampBoardViewState(
                collectdStamp: summary.collected,
                completedBoard: summary.completed,
                stamps: stamps,
                numberOfPages: page == .zero ? page : page + 1
            )
            owner.stampBoardView.render(viewState)
        }.disposed(by: disposeBag)
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        view.backgroundColor = .clear
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
        stampBoardView.setDelegate(self)
    }
}

extension StampBoardViewController: UICollectionViewDelegate {    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        let stampsByPage = viewModel.state.stampsByPage.value
        let itemIndexInPage = indexPath.item % Stamp.totalStamp
        let currentPage = stampBoardView.currentPageValue

        let clickedStamp = stampsByPage[currentPage][itemIndexInPage]
        let missionId = clickedStamp.missionID

        /// Empty Stamp 는 모달뷰 띄우지 않음
        if clickedStamp.type != .gray {
            let viewModel = DIContainer.shared.makeStampInfoViewModel()
            let stampInfoVC = StampInfoViewController(
                viewModel: viewModel,
                stampType: clickedStamp.type,
            )
            stampInfoVC.transitioningDelegate = self
            stampInfoVC.modalPresentationStyle = .custom
            viewModel.action.accept(.load(missionId: missionId))
            
            self.present(stampInfoVC, animated: true)
        }
    }
}

extension StampBoardViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        StampPresentAnimator()
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        StampDismissAnimator()
    }
}
