//
//  MissionListViewController.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/5/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

final class MissionListViewController: UIViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    
    private let navigationBar = DefaultNavigationBar(.plainTitle(title: "미션"))
    
    private let searchBar = UISearchBar().then {
        $0.searchBarStyle = .minimal
        $0.placeholder = "검색어를 입력해주세요"
        $0.searchTextField.font = .pretendard(size: 16, weight: .regular)
        $0.searchTextField.layer.cornerRadius = 18
        $0.searchTextField.clipsToBounds = true
    }
    
    private lazy var tableView = UITableView().then {
        $0.register(MissionListCell.self, forCellReuseIdentifier: MissionListCell.reuseIdentifier)
        $0.keyboardDismissMode = .onDrag
        $0.delegate = self
    }
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
        $0.register(FilterCell.self, forCellWithReuseIdentifier: FilterCell.reuseIdentifier)
        $0.isScrollEnabled = false
    }
    
    private let noResultsView = NoResultsView().then {
        $0.configureContent(title: "검색 결과가 없어요", description: "다른 검색어로 검색해보세요")
        $0.updateContainerTopInset(105)
    }

    private let headerView = HeaderView()
    
    private let toastView = ToastView()
    
    private let viewModel: MissionListViewModel
    private let disposeBag = DisposeBag()
    
    private var dataSource: DataSource?
    
    init(viewModel: MissionListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareSubviews()
        
        setConstraints()
        
        setNavigationBar()
        
        configureDataSource()
        updateSnapshot()
        
        bind()
        
        setCollectionViewCell()
        
        setTapGesture()
        
        // 미션 샘플 데이터 로드
        viewModel.action.accept(.onAppear)
    }
    
    private func prepareSubviews() {
        view.backgroundColor = .white
        
        [navigationBar, searchBar, collectionView, tableView].forEach {
            view.addSubview($0)
        }
    }
    
    private func setConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        searchBar.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(8)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges)
            $0.height.equalTo(36)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(8)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func setNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    private func bind() {
        // 미션 샘플 데이터를 테이블 뷰에 표시
        viewModel.state.missions
            .asDriver(onErrorDriveWith: .empty())
            .drive(tableView.rx.items(cellIdentifier: MissionListCell.reuseIdentifier, cellType: MissionListCell.self)) { (_, element, cell) in
                cell.configure(with: element.title)
            }
            .disposed(by: disposeBag)
        
        // 서치바 검색 결과 뷰 반영
        searchBar.rx.text
            .orEmpty
            .asDriver(onErrorDriveWith: .empty())
            .skip(1)
            .debounce(.milliseconds(300))
            .drive { [weak self] in
                self?.viewModel.action.accept(.searchTextChanged($0))
            }
            .disposed(by: disposeBag)
        
        // 테이블 뷰 셀 선택하면 미션 할당 화면 이동
        tableView.rx.modelSelected(SampleMission.self)
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] in
                guard let self else { return }
                
                viewModel.action.accept(.didSelectTableViewCell($0))
                pushAssignMissionViewController(mission: $0)
            }
            .disposed(by: disposeBag)
        
        // 컬렉션 뷰 셀 선택하면 뷰 반영(해당 카테고리 필터링)
        collectionView.rx.itemSelected
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] in
                guard let self else { return }
                
                viewModel.action.accept(.didSelectCollectionViewCell($0))
            }
            .disposed(by: disposeBag)
        
        // 검색 결과가 없으면 결과없음 레이블 표시
        viewModel.state.missions
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] results in
                guard let self else { return }
                
                if results.isEmpty {
                    tableView.backgroundView = noResultsView
                } else {
                    tableView.backgroundView = nil
                }
            }
            .disposed(by: disposeBag)
        
        // 검색 결과가 있으면 테이블 뷰 헤더에 "ㅇㅇ으로 검색한 결과입니다" 표시
        viewModel.state.searchText
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] searchText in
                guard let self, !searchText.isEmpty else { return }
                
                headerView.configure(with: searchText)
            }
            .disposed(by: disposeBag)
    }
    
    private func setCollectionViewCell() {
        // 전체보기 셀의 isSelected = true로 설정
        let defaultSelection = IndexPath(item: 0, section: 0)
        collectionView.selectItem(at: defaultSelection, animated: false, scrollPosition: [])
    }
    
    // 서치바 바깥 화면을 터치하면 키보드 내려감
    private func setTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // 미션 할당 화면으로 이동
    private func pushAssignMissionViewController(mission: SampleMission) {
        let viewModel = AssignMissionViewModel(mission: mission, missionUseCaseImpl: DIContainer.shared.missionUseCase)
        viewModel.onSuccess = { [weak self] in
            guard let self else { return }
            toastView.show(in: view, duration: 3, message: "미션이 전달되었어요", type: .success)
        }
        let viewController = AssignMissionViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // 컬렉션 뷰 레이아웃 설정
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            return .createFilterSection()
        }
        
        return layout
    }
    
    // 컬렉션 뷰 데이터소스 설정
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .all:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCell.reuseIdentifier, for: indexPath) as! FilterCell
                cell.configure(title: "전체보기", titleColor: .white, backgroundColor: .red400)
                return cell
            case .category(let category):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCell.reuseIdentifier, for: indexPath) as! FilterCell
                cell.configure(image: category.image, title: category.title, titleColor: .gray400, backgroundColor: .white)
                return cell
            }
        }
    }
    
    // 컬렉션 뷰 스냅샷 업데이트
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.category])
        
        var items: [Item] = []
        items.append(.all)
        MissionCategory.allCases.forEach {
            items.append(.category($0))
        }
        snapshot.appendItems(items)
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

extension MissionListViewController: UITableViewDelegate {
    // 검색 결과가 있을 때만 헤더 표시
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.state.missions.value.isEmpty || viewModel.state.searchText.value.isEmpty {
            return nil
        }
        return headerView
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.state.missions.value.isEmpty || viewModel.state.searchText.value.isEmpty {
            return 0
        }
        return 16
    }
}

extension MissionListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // navigationController의 viewControllers가 2개 이상일 때만 pop 허용
        return navigationController?.viewControllers.count ?? 0 > 1
    }
}

// 컬렉션 뷰 섹션/아이템 정의
extension MissionListViewController {
    enum Section: Hashable {
        case category
    }
    
    enum Item: Hashable {
        case all
        case category(MissionCategory)
    }
}
