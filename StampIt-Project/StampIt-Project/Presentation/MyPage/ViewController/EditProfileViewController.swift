//
//  EditProfileViewController.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/17/25.
//

import UIKit

final class EditProfileViewController: UIViewController {
    private let profileImageLabel = UILabel().then {
        $0.text = "프로필 이미지"
        $0.font = .pretendard(size: 14, weight: .regular)
        $0.textColor = .gray400
    }
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout()).then {
        $0.register(ProfileImageCell.self, forCellWithReuseIdentifier: ProfileImageCell.reuseIdentifier)
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
        
        // placeholder 관련
        $0.placeholder = "닉네임"
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        $0.leftView = leftView
        $0.leftViewMode = .always
    }
    
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
        $0.backgroundColor = .gray25
        $0.layer.cornerRadius = 16
        $0.clipsToBounds = true
        $0.layer.borderColor = UIColor.gray200.cgColor
        $0.layer.borderWidth = 1
        
        // placeholder 관련
        $0.placeholder = "그룹명"
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 0))
        $0.leftView = leftView
        $0.leftViewMode = .always
    }
    
    private let alertMessageLabel = UILabel().then {
        $0.text = "그룹명 변경은 그룹장의 권한이에요."
        $0.font = .pretendard(size: 12, weight: .regular)
        $0.textColor = .gray300
        $0.isHidden = false
    }
    
    private let groupNameStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .leading
        $0.spacing = 4
    }
    
    private let editButton = DefaultButton(type: .modify)
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareSubviews()
        
        makeConstraints()
        
        setNavigationBar()
        
        configureDataSource()
        updateSnapshot()
        
        setCollectionViewCell()
    }
    
    private func prepareSubviews() {
        view.backgroundColor = .white
        
        [nicknameLabel, nicknameTextField].forEach {
            nicknameStackView.addArrangedSubview($0)
        }
        
        [groupNameLabel, groupNameTextField].forEach {
            groupNameStackView.addArrangedSubview($0)
        }
        
        [profileImageLabel,
         collectionView,
         nicknameStackView,
         groupNameStackView,
         alertMessageLabel,
         editButton]
            .forEach { view.addSubview($0) }
    }
    
    private func makeConstraints() {
        profileImageLabel.snp.makeConstraints {
            $0.top.leading.equalTo(view.safeAreaLayoutGuide).offset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(profileImageLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(64)
        }
        
        nicknameStackView.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(16)
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
        navigationItem.title = "내 정보 수정"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = .black
        
        // !!!: 이거 호출하는 뷰 컨트롤러에 추가
        let backButtonImage = UIImage(systemName: "arrow.left")
        navigationController?.navigationBar.backIndicatorImage = backButtonImage
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = backButtonImage
        navigationItem.backButtonTitle = ""
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
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .image:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileImageCell.reuseIdentifier, for: indexPath) as! ProfileImageCell
                // cell.configure(with: UIImage(systemName: "add.circle"))
                cell.configure(with: UIImage(named: "profileImage\(indexPath.item + 1)"))
                return cell
            }
        }
    }
    
    // 컬렉션 뷰 스냅샷 업데이트
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.image])
        
        var images: [UIImage] = []
        for index in 0..<8 {
            let image = UIImage(named: "profileImage\(index + 1)")
            if let image {
                images.append(image)
            }
        }
        
        var items: [Item] = []
        images.forEach {
            items.append(.image($0))
        }
        
        snapshot.appendItems(items)
        
        dataSource?.apply(snapshot)
    }
    
    private func setCollectionViewCell() {
        // 일단 첫번째 셀을 selected cell로 설정
        let defaultSelection = IndexPath(item: 0, section: 0)
        collectionView.selectItem(at: defaultSelection, animated: false, scrollPosition: [])
    }
}

// 컬렉션 뷰 섹션/아이템 정의
extension EditProfileViewController {
    enum Section: Hashable {
        case image
    }
    
    enum Item: Hashable {
        case image(UIImage)
    }
}
