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
    
    let closeButtonTapped = PublishRelay<Void>()
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    
    private let bgView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = (UIScreen.main.bounds.width - 16 * 2) / 2
    }
    
    private let MainVStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
        $0.alignment = .center
    }
    
    private let categoryTitle = TagView(type: .filledLightSmall).then {
        $0.updateText(with: "가족소통")
    }
    
    private let SubVStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 30
        $0.alignment = .center
    }
    
    private let missionTitle = UILabel().then {
        $0.font = .pretendard(size: 18, weight: .semibold)
        $0.textColor = .gray800
        $0.numberOfLines = 2
        $0.setTextWithLineHeight(text: "설거지하기 2줄까지 가능해요해요 가능해요", lineHeight: 25)
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
        $0.text = "2025년 10월 10일"
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray500
    }
    
    private let missionSenderTitle = UILabel().then {
        $0.text = "전달한 멤버"
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray500
    }
    
    private let missionSenderValue = UILabel().then {
        $0.text = "멤버명명명"
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
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setStyles()
        setHierarchy()
        setLayout()
        bind()
    }
    
    // MARK: - Bind
    
    private func bind() {
        closeButton.rx.tap
            .bind(to: closeButtonTapped)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Set Styles

    private func setStyles() {
        view.backgroundColor = ._000000.withAlphaComponent(0.3)
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
            .forEach { SubVStackView.addArrangedSubview($0) }
        
        [
            categoryTitle,
            SubVStackView,
        ]
            .forEach { MainVStackView.addArrangedSubview($0) }
        
        [
            MainVStackView,
        ]
            .forEach { bgView.addSubview($0) }
        
        [
            bgView,
        ]
            .forEach { view.addSubview($0) }
    }

    // MARK: - Layout Helper
    
    private func setLayout() {
        bgView.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview().inset(16)
            $0.size.equalTo(UIScreen.main.bounds.width - 16 * 2)
            $0.center.equalToSuperview()
        }
        
        MainVStackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(68)
            $0.center.equalToSuperview()
            $0.directionalHorizontalEdges.equalToSuperview().inset(20)
        }
        
        missionTitle.snp.makeConstraints {
            $0.directionalHorizontalEdges.equalToSuperview().inset(60)
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
