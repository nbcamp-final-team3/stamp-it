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
    private let searchBar = UISearchBar().then {
        $0.searchBarStyle = .minimal
        $0.placeholder = "검색어를 입력해주세요."
    }
    
    private let tableView = UITableView().then {
        $0.register(MissionListCell.self, forCellReuseIdentifier: MissionListCell.reuseIdentifier)
    }
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
        $0.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseIdentifier)
    }
    
    private let viewModel: MissionListViewModel
    private let disposeBag = DisposeBag()
    
    private var dataSource: UICollectionViewDiffableDataSource<MissionListViewModel.Section, MissionListViewModel.Item>?
    
    init(viewModel: MissionListViewModel = .init()) {
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
        
        bind()
        
        // 미션 샘플 데이터 로드
        viewModel.input.accept(.onAppear)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setNavigationBar() // 미션 할당 화면으로 이동 후 복귀 시 내비게이션 라지 타이틀 유지를 위해 필요
    }
    
    private func prepareSubviews() {
        view.backgroundColor = .white
        
        [searchBar, collectionView, tableView].forEach {
            view.addSubview($0)
        }
    }
    
    private func setConstraints() {
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
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
        navigationItem.title = "미션"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // 뒤로 가기 버튼 이미지를 화살표로 바꾸고 타이틀 삭제
        let backButtonImage = UIImage(systemName: "arrow.left")
        navigationController?.navigationBar.backIndicatorImage = backButtonImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonImage
        navigationItem.backButtonTitle = ""
    }
    
    private func bind() {
        // 미션 샘플 데이터를 테이블 뷰에 표시
        viewModel.output.missions
            .asDriver(onErrorDriveWith: .empty())
            .drive(tableView.rx.items(cellIdentifier: MissionListCell.reuseIdentifier, cellType: MissionListCell.self)) { (_, element, cell) in
                cell.configure(with: element.title)
            }
            .disposed(by: disposeBag)
        
        // 컬렉션 뷰 스냅샷 변경 시 뷰 반영
        viewModel.output.snapshot
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] snapshot in
                guard let self, let snapshot, let dataSource else { return }
                dataSource.apply(snapshot, animatingDifferences: true)
            }
            .disposed(by: disposeBag)
        
        // 서치바 검색 결과 뷰 반영
        searchBar.rx.text
            .orEmpty
            .asDriver(onErrorDriveWith: .empty())
            .skip(1)
            .debounce(.milliseconds(300))
            .drive { [weak self] in
                self?.viewModel.input.accept(.searchTextChanged($0))
            }
            .disposed(by: disposeBag)
        
        // 테이블 뷰 셀 선택하면 미션 할당 화면 이동
        tableView.rx.modelSelected(SampleMission.self)
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] in
                guard let self else { return }
                
                viewModel.input.accept(.didSelectTableViewCell($0))
                pushAssignMissionViewController(mission: $0)
            }
            .disposed(by: disposeBag)
        
        // 컬렉션 뷰 셀 선택하면 뷰 반영(해당 카테고리 필터링)
        collectionView.rx.itemSelected
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] in
                guard let self else { return }
                
                viewModel.input.accept(.didSelectCollectionViewCell($0))
            }
            .disposed(by: disposeBag)
    }
    
    // 미션 할당 화면으로 이동
    private func pushAssignMissionViewController(mission: SampleMission) {
        let viewModel = AssignMissionViewModel(mission: mission)
        let viewController = AssignMissionViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // 컬렉션 뷰 레이아웃 설정
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2),
                                                   heightDimension: .absolute(32))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
            section.orthogonalScrollingBehavior = .continuous
            return section
        }
        
        return layout
    }
    
    // 컬렉션 뷰 데이터소스 설정
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<MissionListViewModel.Section, MissionListViewModel.Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .all:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as! CategoryCell
                cell.configure(title: "전체보기", titleColor: .white, titleWeight: .bold, backgroundColor: .red400)
                return cell
            case .category(let category):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.reuseIdentifier, for: indexPath) as! CategoryCell
                cell.configure(image: category.image, title: category.title, titleColor: .darkGray, backgroundColor: .white)
                return cell
            }
        }
    }
}
