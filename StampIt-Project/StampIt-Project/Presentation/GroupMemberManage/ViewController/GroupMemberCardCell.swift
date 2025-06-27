//
//  GroupMemberCardCell.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/15/25.
//

import UIKit
import Then
import SnapKit
import RxSwift
import RxCocoa

final class GroupMemberCardCell: UICollectionViewCell {
    static let reuseIdentifier = "GroupMemberCardCell"

    // MARK: - Actions
    let optionButtonTapped = PublishRelay<IndexPath>()

    // MARK: - Properties
    private var disposeBag = DisposeBag()
    private var indexPath: IndexPath?

    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
    }

    func dispose(disposable: Disposable) {
        disposeBag.insert(disposable)
      }

    // MARK: - UI
    private let profileImageView = UIImageView().then {
        $0.contentMode = .center
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 30
        $0.backgroundColor = .FFFFFF
        $0.layer.borderColor = UIColor.gray200.cgColor
        $0.layer.borderWidth = 1
        $0.layer.opacity = 1
        $0.image = UIImage(named: "profileImage1")
    }

    private let nameLabel = UILabel().then {
        $0.font = .pretendard(size: 16, weight: .semibold)
        $0.textColor = .gray800
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let dateLabel = UILabel().then {
        $0.font = .pretendard(size: 13, weight: .regular)
        $0.textColor = .gray500
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let optionButton = UIButton().then {
        $0.setImage(UIImage(named: "MoreVert"), for: .normal)
        $0.tintColor = .gray300
    }

    private let infoVstack = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 8
        $0.alignment = .leading
    }

    private let hStack = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 16
        $0.alignment = .center
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupShadowAndCorner()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 셀의 레이아웃이 변경될 때마다 contentView의 cornerRadius에 맞춰 그림자 경로를 업데이트하여 성능 최적화
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
    }

    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(hStack)
        contentView.addSubview(optionButton)

        [profileImageView, infoVstack]
            .forEach { hStack.addArrangedSubview($0) }

        [nameLabel, dateLabel]
            .forEach { infoVstack.addArrangedSubview($0) }

        nameLabel.snp.makeConstraints {
            //여유 공간 확보?
            $0.height.equalTo(16)
        }

         infoVstack.snp.makeConstraints {
             $0.centerY.equalTo(profileImageView.snp.centerY)
         }

        hStack.snp.makeConstraints {
            $0.top.leading.bottom.equalToSuperview().inset(16)
        }

        profileImageView.snp.makeConstraints {
            $0.width.height.equalTo(60)
            $0.centerY.equalToSuperview()
        }

        optionButton.snp.makeConstraints {
            $0.width.height.equalTo(28)
            $0.top.equalTo(hStack.snp.top)
            $0.trailing.equalToSuperview().inset(16)
            $0.leading.greaterThanOrEqualTo(hStack.snp.trailing).offset(10)
        }
    }

    // MARK: - Bind
    private func bind() {
        optionButton.rx.tap
            .compactMap { [weak self] in self?.indexPath }
            .bind(to: optionButtonTapped)
            .disposed(by: disposeBag)
    }

    private func setupShadowAndCorner() {
        backgroundColor = .clear
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 1
        layer.shadowOpacity = 0.08
        layer.masksToBounds = false
    }

    // MARK: - Configure
    func configure(with item: GroupMemberManageViewModel.Item, at indexPath: IndexPath) {
        // 셀 재사용 시 이전 구독들을 해제
//        disposeBag = DisposeBag()
        
        self.indexPath = indexPath
        nameLabel.text = item.name
        dateLabel.text = item.date
        profileImageView.image = item.image
        
        // 새로운 구독 설정
//        bind()
    }
}
