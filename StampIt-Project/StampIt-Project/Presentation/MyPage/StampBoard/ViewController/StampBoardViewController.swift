//
//  StampBoardTapViewController.swift
//  StampIt-Project
//
//  Created by kingj on 6/24/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class StampBoardViewController: BaseViewController {
    
    // MARK: - Properties
    
    private var viewModel: StampBoardViewModel
    private var viewState: StampBoardViewState?
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
        setEventStream()
        setStyle()
        setHierarchy()
        setLayout()
        setDelegate()
    }
    
    // MARK: - Bind

    private func setEventStream() {
        let input = StampBoardViewModel.Input(viewDidLoad: Signal.just(()))
        let output = viewModel.transform(from: input)
        bind(with: output)
    }

    private func bind(with output: StampBoardViewModel.Output) {
        output.viewState
            .drive(with: self) { owner, state in
                owner.viewState = state
                owner.stampBoardView.updateContent(state)
            }
            .disposed(by: disposeBag)
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
        guard let state = viewState else { return }
        let stampsByPage = state.stampsByPage
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
