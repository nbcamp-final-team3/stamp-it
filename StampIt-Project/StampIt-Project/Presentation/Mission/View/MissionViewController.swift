//
//  MissionViewController.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/5/25.
//

import UIKit
import RxSwift

final class MissionViewController: UIViewController {
    private let missionView = MissionView()
    private let viewModel = MissionViewModel()
    private let disposeBag = DisposeBag()
    
    override func loadView() {
        view = missionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBar()
        
        bindViewModel()
        
        // 미션 샘플 데이터 로드
        viewModel.input.accept(.onAppear)
    }
    
    private func setNavigationBar() {
        navigationItem.title = "미션"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func bindViewModel() {
        // 미션 샘플 데이터 로드 후 테이블 뷰 업데이트
        viewModel.output.missions
            .skip(1)
            .subscribe { mission in
                print(mission.count)
            }
            .disposed(by: disposeBag)
    }
}
