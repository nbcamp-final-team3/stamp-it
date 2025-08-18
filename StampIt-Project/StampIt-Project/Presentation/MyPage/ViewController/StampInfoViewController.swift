//
//  StampInfo.swift
//  StampIt-Project
//
//  Created by kingj on 6/30/25.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class StampInfoViewController: UIViewController {
    
    // MARK: - Properties
    
    let viewModel: StampInfoViewModel
    
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    let circleView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = (UIScreen.main.bounds.width - 16 * 2) / 2
    }
    
    private let containerVStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
        $0.alignment = .center
    }
    
    private let categoryTitle = TagView(type: .filledLightMedium)
    
    private let contentsVStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 30
        $0.alignment = .center
    }
    
    private let missionTitle = UILabel().then {
        $0.font = .pretendard(size: 18, weight: .semibold)
        $0.textColor = .gray800
        $0.numberOfLines = 2
        $0.lineBreakMode = .byWordWrapping
        $0.textAlignment = .center
    }
    
    private let completedHStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .leading
        $0.spacing = 40
    }
    
    private let senderHStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .leading
        $0.spacing = 40
    }
    
    private let completedDateTitle = UILabel().then {
        $0.text = "완료한 날"
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray500
    }
    
    private let completedDateValue = UILabel().then {
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray500
    }
    
    private let missionSenderTitle = UILabel().then {
        $0.text = "전달한 멤버"
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray500
    }
    
    private let missionSenderValue = UILabel().then {
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray500
    }
    
    private let vStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 16
    }
    
    private lazy var closeButton = UIButton().then {
        $0.setTitle("닫기", for: .normal)
        $0.titleLabel?.font = .pretendard(size: 14, weight: .semibold)
        $0.backgroundColor = .red50
        $0.setTitleColor(.red300, for: .normal)
        $0.layer.cornerRadius = 8
    }
    
    // MARK: - Initializer, Deinit, requiered
    
    init(
        viewModel: StampInfoViewModel
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
        setHierarchy()
        setLayout()
        bind()
    }
    
    // MARK: - Bind
    
    private func bind() {
        closeButton.rx.tap
            .subscribe(with: self) { owned, _ in
                owned.viewModel.action.accept(.closeButtonTapped)
            }.disposed(by: disposeBag)
        
        viewModel.state.isDismissed
            .asDriver()
            .filter { $0 }
            .drive(with: self) { owned, _ in
                owned.dismiss(animated: true)
            }.disposed(by: disposeBag)

        viewModel.state.mission
            .asDriver()
            .drive(with: self) { owned, mission in
                guard let mission else {
                    /// 그룹 탈퇴하여 받은 미션이 삭제된 경우
                    owned.updateUI(
                        with: MissionUI(
                            missionID: .init(),
                            title: "탈퇴한 그룹에서 받은 스탬프",
                            assignedBy: "탈퇴한 그룹 멤버",
                            dueDate: "탈퇴한 그룹에서 완료",
                            category: .custom
                        )
                    )
                    owned.categoryTitle.isHidden = true
                    return
                }
                owned.updateUI(with: mission)
                owned.categoryTitle.isHidden = false
            }.disposed(by: disposeBag)
    }

    // MARK: - Method

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        missionTitle.preferredMaxLayoutWidth = missionTitle.frame.width
    }
    
    private func updateUI(with mission: MissionUI) {
        categoryTitle.updateText(with: mission.category.title)
        
        missionTitle.setTextWithLineHeight(
            text: mission.title,
            lineHeight: 25
        )
        
        completedDateValue.text = "\(mission.dueDate)"
        missionSenderValue.text = mission.assignedBy
    }

    // MARK: - Hierarchy Helper
    
    private func setHierarchy() {
        [
            completedHStackView,
            senderHStackView,
        ]
            .forEach { vStackView.addArrangedSubview($0) }
        
        [
            completedDateTitle,
            completedDateValue,
        ]
            .forEach { completedHStackView.addArrangedSubview($0) }
        
        [
            missionSenderTitle,
            missionSenderValue,
        ]
            .forEach { senderHStackView.addArrangedSubview($0) }
        
        [
            missionTitle,
            vStackView,
            closeButton,
        ]
            .forEach { contentsVStackView.addArrangedSubview($0) }
        
        [
            categoryTitle,
            contentsVStackView,
        ]
            .forEach { containerVStackView.addArrangedSubview($0) }
        
        [
            containerVStackView,
        ]
            .forEach { circleView.addSubview($0) }
        
        [
            circleView,
        ]
            .forEach { view.addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        circleView.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview().inset(16)
            $0.size.equalTo(UIScreen.main.bounds.width - 16 * 2)
            $0.center.equalToSuperview()
        }
        
        containerVStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(68)
            $0.center.equalToSuperview()
            $0.directionalHorizontalEdges.equalToSuperview().inset(40)
        }
        
        missionTitle.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview()
        }
        
        completedHStackView.snp.makeConstraints {
            $0.height.equalTo(completedDateTitle)
        }
        
        completedDateTitle.snp.makeConstraints {
            $0.width.equalTo(75)
        }
        
        senderHStackView.snp.makeConstraints {
            $0.height.equalTo(missionSenderTitle)
        }
        
        missionSenderTitle.snp.makeConstraints {
            $0.width.equalTo(75)
        }
        
        closeButton.snp.makeConstraints {
            $0.height.equalTo(33)
            $0.width.equalTo(48)
        }
    }
}
