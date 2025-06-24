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
    
    private let viewModel: MyPageViewModel
    private let container: DIContainer
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    private lazy var viewControllers: [UIViewController] = [
        container.makeStampBoardViewController(),
        container.makeProfileViewController()
    ]
    
    private lazy var pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    ).then {
        $0.setViewControllers(
            [viewControllers[0]],
            direction: .forward,
            animated: false
        )
    }
    
    private let navigationBar = DefaultNavigationBar(
        .segmentedControlTabs(
            tab1: TabType.stampBoard.title,
            tab2: TabType.profile.title
        ))
    
    // MARK: - Initializer, Deinit, requiered
    
    init(
        viewModel: MyPageViewModel,
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
        setStyle()
        setHierarchy()
        setLayout()
        setDelegate()
        setDataSource()
        bind()
    }
    
    // MARK: - Bind
    
    private func bind() {
        navigationBar.tabTapped
            .bind(with: self) { owner, type in
                owner.viewModel.action.accept(
                    .tabChanged(TabType(rawValue: type.rawValue)!)
                )
            }.disposed(by: disposeBag)
    
        viewModel.state.tabType
            .bind(with: self) { owner, tab in
                owner.navigationBar.updateTabTitleColor(selected: tab)
                owner.updateSelectedTab(selected: tab)
            }.disposed(by: disposeBag)
    }
    
    // MARK: - Style Helper
    
    private func setStyle() {
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        /// 자식 ViewController 로 설정
        addChild(pageViewController)
        
        [
            navigationBar,
            pageViewController.view
        ]
            .forEach { view.addSubview($0) }
        
        /// 자식 ViewController 에 didMove 호출
        pageViewController.didMove(toParent: self)
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        navigationBar.snp.makeConstraints {
            $0.top.directionalHorizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        pageViewController.view.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.bottom.directionalHorizontalEdges.equalToSuperview()
        }
    }
    
    // MARK: - Delegate Helper
    
    private func setDelegate() {
        pageViewController.delegate = self
    }

    // MARK: - DataSource Helper
    
    private func setDataSource() {
        pageViewController.dataSource = self
    }
    
    // MARK: - Methods
    
    /// 탭 클릭시 ViewController 전환
    private func updateSelectedTab(selected: TabType) {
        guard let currenctVC = pageViewController.viewControllers?.first,
              let currentIndex = viewControllers.firstIndex(of: currenctVC) else { return }
        
        let newIndex = selected.index
        
        /// 같은 탭이면 무시
        guard newIndex != currentIndex else { return }
        
        let direction: UIPageViewController.NavigationDirection = newIndex > currentIndex ? .forward : .reverse
        
        pageViewController.setViewControllers(
            [viewControllers[newIndex]],
            direction: direction,
            animated: true
        )
    }
}

/// Swiping 하여 ViewController 전환
extension MyPageViewController: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed,
           let newVC = pageViewController.viewControllers?.first,
           let newIndex = viewControllers.firstIndex(of: newVC) {
            viewModel.action.accept(
                .tabChanged(TabType.index(newIndex))
            )
        }
    }
}

extension MyPageViewController: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let currentIndex = viewControllers.firstIndex(of: viewController),
              currentIndex > 0 else { return nil }
        return viewControllers[currentIndex - 1]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let currentIndex = viewControllers.firstIndex(of: viewController),
              currentIndex < viewControllers.count - 1 else { return nil }
        return viewControllers[currentIndex + 1]
    }
}
