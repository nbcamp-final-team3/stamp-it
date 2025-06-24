//
//  EditProfileViewController.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/17/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

final class EditProfileViewController: UIViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    
    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "내 정보 수정"))
    
    private let profileImageLabel = UILabel().then {
        $0.text = "프로필 이미지"
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .gray400
    }
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
        $0.register(ProfileImageCell.self, forCellWithReuseIdentifier: ProfileImageCell.reuseIdentifier)
        $0.isScrollEnabled = false
    }
    
    private let nicknameLabel = UILabel().then {
        $0.text = "닉네임"
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .gray400
    }
    
    private let nicknameTextField = UITextField().then {
        $0.font = .pretendard(size: 18, weight: .bold)
        $0.textColor = .gray300
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
        $0.layer.borderColor = UIColor.gray200.cgColor
        $0.layer.borderWidth = 1
        $0.clearButtonMode = .whileEditing
        
        // placeholder 관련
        $0.placeholder = "닉네임"
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        $0.leftView = leftView
        $0.leftViewMode = .always
    }
    
    // nicknameLabel + nicknameTextField
    private let nicknameStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 4
    }
    
    private let groupNameLabel = UILabel().then {
        $0.text = "그룹명"
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .gray400
    }
    
    private let groupNameTextField = UITextField().then {
        $0.font = .pretendard(size: 18, weight: .bold)
        $0.textColor = .gray300
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
        $0.layer.borderColor = UIColor.gray200.cgColor
        $0.layer.borderWidth = 1
        $0.clearButtonMode = .whileEditing
        
        // placeholder 관련
        $0.placeholder = "그룹명"
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        $0.leftView = leftView
        $0.leftViewMode = .always
    }
    
    // groupNameLabel + groupNameTextField
    private let groupNameStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 4
    }
    
    private let alertMessageLabel = UILabel().then {
        $0.text = "그룹명 변경은 그룹장의 권한이에요."
        $0.font = .pretendard(size: 12, weight: .regular)
        $0.textColor = .gray300
    }
    
    private let editButton = DefaultButton(type: .modify)
    
    private let toastView = ToastView()
    
    private let viewModel: EditProfileViewModel
    private let disposeBag = DisposeBag()
    
    // 프로필 이미지 에셋
    private let profileImages = ["profileImage1", "profileImage2", "profileImage3", "profileImage4", "profileImage5", "profileImage6", "profileImage7", "profileImage8"]
    
    private var dataSource: DataSource?
    
    init(viewModel: EditProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("editProfileViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareSubviews()
        
        makeConstraints()
        
        setNavigationBar()
        setButtonAction()
        
        configureDataSource()
        updateSnapshot()
        
        bind()
        
        setupSelectedProfileImage()
        
        viewModel.action.accept(.onAppear)
    }
    
    private func prepareSubviews() {
        view.backgroundColor = .white
        
        [nicknameLabel, nicknameTextField].forEach {
            nicknameStackView.addArrangedSubview($0)
        }
        
        [groupNameLabel, groupNameTextField].forEach {
            groupNameStackView.addArrangedSubview($0)
        }
        
        [navigationBar,
         profileImageLabel,
         collectionView,
         nicknameStackView,
         groupNameStackView,
         alertMessageLabel,
         editButton]
            .forEach { view.addSubview($0) }
    }
    
    private func makeConstraints() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
        }
        
        profileImageLabel.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom).offset(16)
            $0.leading.equalTo(view.safeAreaLayoutGuide).offset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(profileImageLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(64)
        }
        
        nicknameStackView.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(24)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        nicknameTextField.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(72)
        }
        
        groupNameStackView.snp.makeConstraints {
            $0.top.equalTo(nicknameStackView.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        
        groupNameTextField.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview()
            $0.height.equalTo(72)
        }
        
        alertMessageLabel.snp.makeConstraints {
            $0.top.equalTo(groupNameStackView.snp.bottom).offset(4)
            $0.leading.equalToSuperview().offset(24)
        }
        
        editButton.snp.makeConstraints {
            $0.top.equalTo(groupNameStackView.snp.bottom).offset(40)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    private func setNavigationBar() {        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setButtonAction() {
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }
    
    private func bind() {
        // 닉네임 텍스트필드와 그룹 텍스트필드에 유저 정보 반영
        viewModel.state.user
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] user in
                guard let self, let user else { return }
                
                nicknameTextField.text = user.nickname
                groupNameTextField.text = user.groupName
            }
            .disposed(by: disposeBag)
        
        // 유저가 그룹장이 아니면 그룹 텍스트필드 비활성화
        viewModel.state.user
            .map { $0?.isLeader }
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] isLeader in
                guard let self, let isLeader else { return }
                
                isTextFieldEnabled(isLeader: isLeader)
            }
            .disposed(by: disposeBag)
        
        // 닉네임 변경 추적
        nicknameTextField.rx.text
            .orEmpty
            .asDriver(onErrorDriveWith: .empty())
            .distinctUntilChanged()
            .skip(1)
            .drive { [weak self] in
                self?.viewModel.action.accept(.nicknameChanged($0))
            }
            .disposed(by: disposeBag)
        
        // 닉네임 변경 시 글자수 검증 에러 출력
        viewModel.state.nicknameError
            .asDriver(onErrorDriveWith: .empty())
            .skip(1)
            .drive { [weak self] message in
                guard let self, let message else { return }
                toastView.show(in: view, duration: 3, message: message, type: .failure)
            }
            .disposed(by: disposeBag)
        
        // 그룹명 변경 추적
        groupNameTextField.rx.text
            .orEmpty
            .asDriver(onErrorDriveWith: .empty())
            .distinctUntilChanged()
            .skip(1)
            .drive { [weak self] in
                self?.viewModel.action.accept(.groupNameChanged($0))
            }
            .disposed(by: disposeBag)
        
        // 프로필 이미지 변경 추적
        collectionView.rx.itemSelected
            .asDriver(onErrorDriveWith: .empty())
            .distinctUntilChanged()
            .drive { [weak self] in
                self?.viewModel.action.accept(.profileImageChanged($0))
            }
            .disposed(by: disposeBag)
        
        // 3개의 유저 데이터(닉네임, 그룹명, 이미지) 중 하나라도 변경사항이 있는지 추적
        viewModel.state.isUserDataChanged
            .asDriver(onErrorDriveWith: .empty())
            .drive { [weak self] isChanged in
                guard let self else { return }
                
                if isChanged {
                    editButton.isEnabled = true
                } else {
                    editButton.isEnabled = false
                }
            }
            .disposed(by: disposeBag)
        
        // 내비게이션 백버튼 누를 때
        navigationBar.backTapped
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    // 컬렉션 뷰 레이아웃 설정
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(60), heightDimension: .absolute(60))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.orthogonalScrollingBehavior = .continuous
            return section
        }
        return layout
    }
    
    // 컬렉션 뷰 데이터소스 설정
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .image:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileImageCell.reuseIdentifier, for: indexPath) as! ProfileImageCell
                let image = UIImage(named: "profileImage\(indexPath.item + 1)")
                cell.configure(with: image)
                return cell
            }
        }
    }
    
    // 컬렉션 뷰 스냅샷 업데이트
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.image])
        
        var items: [Item] = []
        profileImages.forEach {
            items.append(.image($0))
        }
        
        snapshot.appendItems(items)
        
        dataSource?.apply(snapshot)
    }
    
    // 기존 프로필 이미지를 선택된 상태(isSelected)로 설정
    private func setupSelectedProfileImage() {
        let profileImage = viewModel.state.user.value?.profileImage
        
        // 기존 프로필 이미지가 존재하면, 해당 이미지를 선택된 상태(isSelected)로 설정
        if let profileImage, profileImages.contains(profileImage) {
            let index = profileImages.firstIndex(of: profileImage)!
            let selectedImage = IndexPath(item: index, section: 0)
            collectionView.selectItem(at: selectedImage, animated: false, scrollPosition: [])
        } else {
            // 기존 프로필 이미지가 없으면, 첫번째 이미지를 선택된 상태(isSelected)로 설정
            let defaultSelection = IndexPath(item: 0, section: 0)
            collectionView.selectItem(at: defaultSelection, animated: false, scrollPosition: [])
        }
    }
    
    // 그룹 텍스트필드 활성화 헬퍼 메서드
    private func isTextFieldEnabled(isLeader: Bool) {
        if !isLeader {
            groupNameTextField.isEnabled = false
            groupNameTextField.backgroundColor = .gray25
            alertMessageLabel.isHidden = false
        } else {
            groupNameTextField.isEnabled = true
            groupNameTextField.backgroundColor = .white
            alertMessageLabel.isHidden = true
        }
    }
    
    @objc private func editButtonTapped() {
        viewModel.action.accept(.didTapEditButton)
        dismiss()
    }
    
    // 수정하기 버튼 누르면 원래 화면으로 복귀
    private func dismiss() {
        navigationController?.popViewController(animated: true)
        print("dismiss")
    }
}

// 컬렉션 뷰 섹션/아이템 정의
extension EditProfileViewController {
    enum Section: Hashable {
        case image
    }
    
    enum Item: Hashable {
        case image(String)
    }
}
