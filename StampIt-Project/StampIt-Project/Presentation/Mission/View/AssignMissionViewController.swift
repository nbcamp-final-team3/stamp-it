//
//  AssignMissionViewController.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/8/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

final class AssignMissionViewController: UIViewController {
    private let memberLabel = UILabel().then {
        $0.text = "미션을 수행할 구성원"
    }
    
    // 멤버 선택 메뉴 버튼
    private lazy var memberMenuButton = UIButton().then {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .systemGray6
        configuration.baseForegroundColor = .label
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        configuration.cornerStyle = .medium
        configuration.title = "구성원 선택하기"
        
        $0.configuration = configuration
        $0.showsMenuAsPrimaryAction = true
        $0.menu = createMenu()
    }
    
    // memberLabel + memberMenuButton
    private let memberStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .equalCentering
    }
    
    private let dueDateLabel = UILabel().then {
        $0.text = "미션 기한"
    }
    
    // 날짜 선택 피커
    private let dueDatePicker = UIDatePicker().then {
        $0.preferredDatePickerStyle = .compact
        $0.datePickerMode = .date
        $0.tintColor = .systemRed
    }
    
    // dueDateLabel + dueDatePicker
    private let dueDateStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .equalCentering
    }
    
    // 전달하기 버튼(화면 맨 아래)
    private let assignButton = DefaultButton(type: .send).then {
        $0.isEnabled = false
    }
    
    private let viewModel: AssignMissionViewModel
    private let disposeBag = DisposeBag()
    
    init(viewModel: AssignMissionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinit AssignMissionViewController")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareSubviews()
        
        setConstraints()
        
        setNavigationBar()
        
        bind()
        
        viewModel.input.accept(.onAppear)
    }
    
    private func prepareSubviews() {
        view.backgroundColor = .white
        
        [memberStackView, dueDateStackView, assignButton].forEach {
            view.addSubview($0)
        }
        
        [memberLabel, memberMenuButton].forEach {
            memberStackView.addArrangedSubview($0)
        }
        
        [dueDateLabel, dueDatePicker].forEach {
            dueDateStackView.addArrangedSubview($0)
        }
    }
    
    private func setConstraints() {
        memberStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        dueDateStackView.snp.makeConstraints {
            $0.top.equalTo(memberStackView.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        assignButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    private func setNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .black
    }
    
    private func bind() {
        // 내비게이션 타이틀 설정
        viewModel.output.mission
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] mission in
                guard let self, let mission else { return }
                navigationItem.title = mission.title
            }
            .disposed(by: disposeBag)
        
        // "미션을 수행할 구성원" 메뉴 버튼에 멤버 전체 데이터 반영
        viewModel.output.members
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] member in
                guard let self else { return }
                memberMenuButton.menu = createMenu()
            }
            .disposed(by: disposeBag)
        
        // 사용자가 멤버 선택 시
        viewModel.output.selectedMember
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] member in
                guard let self, let member else { return }
                memberMenuButton.setTitle("\(member.nickname)", for: .normal) // 버튼에 선택한 멤버 이름 표시
                assignButton.isEnabled = true // 전달하기 버튼 활성화
            }
            .disposed(by: disposeBag)
        
        // 사용자가 날짜 선택 시
        dueDatePicker.rx.date
            .asDriver(onErrorDriveWith: .empty())
            .distinctUntilChanged()
            .drive { date in
                print("due date: \(date)")
            }
            .disposed(by: disposeBag)
        
        // 전달하기 버튼 누를 때
        assignButton.rx.tap
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] _ in
                guard let self else { return }
                viewModel.input.accept(.didTapAssignButton)
                dismiss()
            }
            .disposed(by: disposeBag)
    }
    
    // "미션을 수행할 구성원" 메뉴 버튼 구성 헬퍼
    private func createMenu() -> UIMenu {
        let members = viewModel.output.members.value
        let actions = members.map { member in
            UIAction(title: member.nickname) { [weak self] _ in
                self?.viewModel.input.accept(.didSelectMember(member))
            }
        }
        
        return UIMenu(children: actions)
    }
    
    // 전달하기 버튼 누르면 원래 화면으로 복귀
    private func dismiss() {
        navigationController?.popViewController(animated: true)
    }
}
