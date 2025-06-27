//
//  AssignMissionViewController.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/8/25.
//

import UIKit
import SwiftUI
import RxSwift
import RxCocoa
import SnapKit
import Then

final class AssignMissionViewController: UIViewController {
    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "미션 전달하기"))
    
    private let missionTitleLabel = UILabel().then {
        $0.font = .pretendard(size: 18, weight: .bold)
    }
    
    private let memberLabel = UILabel().then {
        $0.text = "미션을 수행할 멤버"
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray800
    }
    
    // 멤버 선택 버튼
    private lazy var memberSelectionButton = UIButton().then {
        $0.titleLabel?.numberOfLines = 1
        $0.configuration = configureButton(title: "멤버 선택하기", titleColor: .gray200)
        $0.addTarget(self, action: #selector(dropdown), for: .touchUpInside)
    }
    
    // 멤버 선택 버튼을 누르면 드랍다운으로 멤버 리스트를 보여줌.
    private let dropdownView = UIStackView().then {
        $0.axis = .vertical
        $0.distribution = .fillEqually
        $0.spacing = 1
        $0.isHidden = true
        $0.layer.cornerRadius = 8
        $0.clipsToBounds = true
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.gray50.cgColor
        $0.backgroundColor = .gray25
    }
    
    // memberLabel + memberSelectionButton
    private let memberStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.distribution = .equalSpacing
    }
    
    private lazy var dueDateView: UIView = {
        let hostingController = UIHostingController(rootView: DueDateView { [weak self] selectedDate in
            self?.viewModel.action.accept(.didSelectDueDate(selectedDate))
        })
        hostingController.view.backgroundColor = .clear
        return hostingController.view
    }()
    
    // 미션 전달하기 버튼(화면 맨 아래)
    private let assignButton = DefaultButton(type: .send).then {
        $0.isEnabled = false
    }
    
    private let toastView = ToastView()
    
    private let viewModel: AssignMissionViewModel
    private let disposeBag = DisposeBag()
    
    private var isDropdown = false // 멤버 선택 버튼이 눌려서 멤버 리스트가 펼쳐있는 상태인지 여부
    
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
        
        viewModel.action.accept(.onAppear)
    }
    
    private func prepareSubviews() {
        view.backgroundColor = .white
        
        // dropdownView는 보여질 때 일부 화면이 가려지므로(예: dueDateStackView) 마지막에 서브 뷰로 추가
        [navigationBar, missionTitleLabel, memberStackView, dueDateView, assignButton, dropdownView].forEach {
            view.addSubview($0)
        }
        
        [memberLabel, memberSelectionButton].forEach {
            memberStackView.addArrangedSubview($0)
        }
    }
    
    private func setConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        
        missionTitleLabel.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        memberStackView.snp.makeConstraints {
            $0.top.equalTo(missionTitleLabel.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        dueDateView.snp.makeConstraints {
            $0.top.equalTo(memberStackView.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        assignButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        memberSelectionButton.snp.makeConstraints {
            $0.width.equalTo(144)
        }
        
        dropdownView.snp.makeConstraints {
            $0.top.equalTo(memberSelectionButton.snp.bottom).offset(4)
            $0.horizontalEdges.equalTo(memberSelectionButton.snp.horizontalEdges)
        }
    }
    
    private func setNavigationBar() {        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func bind() {
        // 미션 제목 뷰에 반영
        viewModel.state.mission
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] mission in
                guard let self, let mission else { return }
                missionTitleLabel.text = mission.title
            }
            .disposed(by: disposeBag)
        
        // 멤버 선택 버튼의 멤버 리스트(드랍 다운 형태)에 데이터 반영
        viewModel.state.members
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] members in
                guard let self else { return }
                
                setupDropdownView(members: members)
            }
            .disposed(by: disposeBag)
        
        // 사용자가 멤버 선택 시
        viewModel.state.selectedMember
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] member in
                guard let self, let member else { return }
                
                memberSelectionButton.configuration = configureButton(title: member.nickname, titleColor: .gray800) // 버튼에 선택한 멤버 이름 표시
                assignButton.isEnabled = true // 미션 전달하기 버튼 활성화
                dropdownView.isHidden = true
                isDropdown = false
            }
            .disposed(by: disposeBag)
        
        // 전달하기 버튼 누를 때
        assignButton.rx.tap
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] _ in
                guard let self else { return }
                viewModel.action.accept(.didTapAssignButton)
                dismiss()
            }
            .disposed(by: disposeBag)
        
        // 내비게이션 백버튼 누를 때
        navigationBar.backTapped
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    // 멤버 선택 버튼 configuration 설정
    private func configureButton(title: String, titleColor: UIColor) -> UIButton.Configuration {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .gray25
        configuration.baseForegroundColor = .gray800
        configuration.cornerStyle = .medium
        configuration.title = title
        configuration.titleLineBreakMode = .byTruncatingTail
        
        // 폰트 및 폰트 색상 설정
        let font = UIFont.pretendard(size: 16, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: titleColor]
        let attributedTitle = NSAttributedString(string: configuration.title ?? "", attributes: attributes)
        configuration.attributedTitle = AttributedString(attributedTitle)
        
        return configuration
    }
    
    // 멤버 리스트 구성 헬퍼
    private func setupDropdownView(members: [Member]) {
        for member in members {
            let button = MemberButton(member: member)
            button.addTarget(self, action: #selector(memberSelected), for: .touchUpInside)
            dropdownView.addArrangedSubview(button)
        }
    }
    
    @objc private func memberSelected(_ sender: UIButton) {
        let button = sender as? MemberButton
        let member = button?.getMember()
        guard let member else { return }
        
        viewModel.action.accept(.didSelectMember(member))
    }
    
    // 멤버 선택 버튼을 누르면 드랍다운으로 멤버 리스트를 보여줌. 다시 누르면 닫음.
    @objc private func dropdown() {
        if viewModel.state.members.value.isEmpty {
            toastView.show(in: view, duration: 3, message: "미션을 줄 멤버가 없습니다", type: .success)
            return
        }
        
        isDropdown.toggle()
        
        if isDropdown {
            dropdownView.alpha = 0
            dropdownView.isHidden = false
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.dropdownView.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.dropdownView.alpha = 0
            } completion: { [weak self] _ in
                self?.dropdownView.isHidden = true
            }
        }
    }
    
    // 전달하기 버튼 누르면 원래 화면으로 복귀
    private func dismiss() {
        navigationController?.popViewController(animated: true)
    }
}
