//
//  OnboardingViewController.swift
//  StampIt-Project
//
//  Created by iOS study on 6/14/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Then

final class OnboardingViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: OnboardingViewModel
    private let disposeBag = DisposeBag()
    private var imageWidthConstraint: Constraint?
    private var imageHeightConstraint: Constraint?
    
    private let onboardingData: [(image: String, title: String?, desc: String?)] = [
        ("MascotCharacterSad", nil, "해도해도 끝나지 않는 집안일,\n혼자 하기 벅차지 않으세요?"),
        ("MascotCharacterGroup", nil, "구성원들과 미션을 주고 받으며\n집안일을 즐겁게 해보세요!"),
        ("MascotCharacterGroup", "함께하는 집안일,\nStamp It!", nil)
    ]
    
    // MARK: - UI Components
    private let pageControl = CustomPageControl()
    
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .clear
    }
    
    private let titleLabel = UILabel().then {
        $0.textAlignment = .center
        $0.numberOfLines = 2
        $0.font = .pretendard(size: 20, weight: .bold)
        $0.textColor = .label
    }
    
    private let descLabel = UILabel().then {
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.font = .pretendard(size: 20, weight: .medium)
        $0.textColor = .label
    }
    
    private let skipButton = UIButton(type: .system).then {
        $0.setTitle("건너뛰기", for: .normal)
        $0.setTitleColor(.label, for: .normal)
        $0.titleLabel?.font = .pretendard(size: 14, weight: .regular)
    }
    
    private let actionButton = DefaultButton(type: .proceed(isFinalStep: false))
    
    // MARK: - Init
    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindUI()
        bindViewModel()
        updateUI(state: viewModel.state)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        pageControl.configure(numberOfPages: onboardingData.count, currentPage: 0)
        
        [imageView, titleLabel, descLabel, pageControl, skipButton, actionButton].forEach {
            view.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(150)
            self.imageWidthConstraint = $0.width.equalTo(160).constraint
            self.imageHeightConstraint = $0.height.equalTo(160).constraint
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(imageView.snp.bottom).offset(30)
            $0.leading.trailing.equalToSuperview().inset(28)
        }
        descLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview().inset(28)
        }
        pageControl.snp.makeConstraints {
            $0.bottom.equalTo(actionButton.snp.top).offset(-32)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(8)
        }
        skipButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(5)
            $0.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(40)
        }
        actionButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(56)
        }
    }
    
    // MARK: - Bindings
    private func bindUI() {
        actionButton.rx.tap
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind { [weak self] in
                self?.viewModel.send(.nextPage)
            }
            .disposed(by: disposeBag)
        
        skipButton.rx.tap
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind { [weak self] in
                self?.viewModel.send(.skip)
            }
            .disposed(by: disposeBag)
    }
    
    /// 뷰모델의 상태 변화와 완료 이벤트를 바인딩
    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.updateUI(state: state)
        }
        viewModel.onComplete = { [weak self] in
            self?.completeOnboardingAndGoToLogin()
        }
    }
    
    // MARK: - UI 업데이트
    /// 뷰모델 상태에 따라 UI를 업데이트
    private func updateUI(state: OnboardingState) {
        let data = onboardingData[state.currentPage]
        imageView.image = UIImage(named: data.image)
        
        // 페이지별 이미지 크기 최적화
        switch state.currentPage {
        case 0: // 첫 번째 페이지 - 슬픈 캐릭터 (단일)
            imageWidthConstraint?.update(offset: 180)
            imageHeightConstraint?.update(offset: 200)
            
        case 1, 2: // 두 번째, 세 번째 페이지 - 그룹 캐릭터들
            imageWidthConstraint?.update(offset: 280)
            imageHeightConstraint?.update(offset: 200)
        default:
            imageWidthConstraint?.update(offset: 200)
            imageHeightConstraint?.update(offset: 200)
        }
        
        // 타이틀/설명 분기
        if let title = data.title {
            let attributed = NSMutableAttributedString(string: title)
            // "Stamp It!"만 Bold로 처리
            if let range = title.range(of: "Stamp It!") {
                let nsRange = NSRange(range, in: title)
                attributed.addAttribute(.font, value: UIFont.pretendard(size: 20, weight: .bold), range: nsRange)
            }
            titleLabel.attributedText = attributed
            descLabel.text = nil
            descLabel.isHidden = true
        } else {
            titleLabel.text = nil
            descLabel.text = data.desc
            descLabel.isHidden = false
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.view.layoutIfNeeded()
        }
        
        pageControl.setCurrentPage(state.currentPage, animated: true)
        let isLast = state.currentPage == onboardingData.count - 1
        actionButton.updateProceed(isFinalStep: isLast)
    }
    
    // MARK: - 온보딩 완료 처리
    /// 온보딩 완료 후 로그인 화면으로 전환
    private func completeOnboardingAndGoToLogin() {
        UserDefaults.standard.set(true, forKey: "hasOnboarded")
        let loginVC = DIContainer.shared.makeLoginViewController()
        // windowScene iOS 15+ 권장 방식 사용
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UINavigationController(rootViewController: loginVC)
            window.makeKeyAndVisible()
        } else {
            navigationController?.setViewControllers([loginVC], animated: true)
        }
    }
}
