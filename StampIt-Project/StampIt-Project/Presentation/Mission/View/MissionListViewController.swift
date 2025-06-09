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
    
    private let viewModel: MissionListViewModel
    private let disposeBag = DisposeBag()
    
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
        
        bind()
        
        // 미션 샘플 데이터 로드
        viewModel.input.accept(.onAppear)
    }
    
    private func prepareSubviews() {
        view.backgroundColor = .white
        
        [searchBar, tableView].forEach {
            view.addSubview($0)
        }
    }
    
    private func setConstraints() {
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.horizontalEdges.equalToSuperview()
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(8)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func setNavigationBar() {
        navigationItem.title = "미션"
        navigationController?.navigationBar.prefersLargeTitles = true
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
    }
    
    private func pushAssignMissionViewController(mission: SampleMission) {
        let viewModel = AssignMissionViewModel(mission: mission)
        let viewController = AssignMissionViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
