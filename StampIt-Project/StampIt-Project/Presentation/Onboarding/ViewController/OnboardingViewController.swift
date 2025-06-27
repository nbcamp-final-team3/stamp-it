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
    private var previousPage: Int = 0 // 이전 페이지 추적
    
//    private let onboardingData: [(image: String, title: String?, desc: String?)] = [
//        ("MascotCharacterSad", nil, "해도해도 끝나지 않는 집안일,\n혼자 하기 벅차지 않으세요?"),
//        ("MascotCharacterGroup", nil, "구성원들과 미션을 주고 받으며\n집안일을 즐겁게 해보세요!"),
//        ("MascotCharacterGroup", "함께하는 집안일,\nStamp It!", nil)
//    ]
    
    private let onboardingData: [(image: String, title: String?, desc: String?)] = [
        ("MascotCharacterSad", nil, "가족, 룸메이트, 친구들과 좋은 습관,\n같이 만들고 싶은데 쉽지 않죠?"),
        ("MascotCharacterGroup", nil, "미션과 스탬프 보상으로 모두가\n즐겁게 습관을 만들어갈 수 있어요!"),
        ("MascotCharacterGroup", "'Stamp it'으로 협력하는\n공동체 생활을 경험해보세요!", nil)
    ]
    
    // MARK: - UI Components
    private let pageControl = CustomPageControl()
    
    // 기존 imageView 대신 애니메이션 컨테이너 사용
    private let animationContainer = UIView().then {
        $0.backgroundColor = .clear
    }
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCurrentAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCurrentAnimation()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        pageControl.configure(numberOfPages: onboardingData.count, currentPage: 0)
        
        animationContainer.addSubview(imageView)
        [animationContainer, titleLabel, descLabel, pageControl, skipButton, actionButton].forEach {
            view.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        animationContainer.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(150)
            self.imageWidthConstraint = $0.width.equalTo(160).constraint
            self.imageHeightConstraint = $0.height.equalTo(160).constraint
        }
        
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(animationContainer.snp.bottom).offset(30)
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
    
    // MARK: - Animation Methods
    private func setupFloatingAnimation() {
        // 애니메이션이 없는 경우에만 시작
        if imageView.layer.animation(forKey: "floating") == nil {
            setupDefaultFloatingAnimation()
        }
    }
    
    private func setupDefaultFloatingAnimation() {
        // 기본 둥둥 떠다니는 애니메이션
        let floatingAnimation = CABasicAnimation(keyPath: "transform.translation.y")
        floatingAnimation.fromValue = -10
        floatingAnimation.toValue = 10
        floatingAnimation.duration = 2.0
        floatingAnimation.autoreverses = true
        floatingAnimation.repeatCount = .infinity
        floatingAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        imageView.layer.add(floatingAnimation, forKey: "floating")
        
        // 약간의 회전 애니메이션도 추가
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = -0.05 // 약 2도
        rotationAnimation.toValue = 0.05
        rotationAnimation.duration = 2.0
        rotationAnimation.autoreverses = true
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        imageView.layer.add(rotationAnimation, forKey: "rotation")
    }
    
    private func startCurrentAnimation() {
        setupFloatingAnimation()
    }
    
    private func stopCurrentAnimation() {
        // 기본 애니메이션 정지
        imageView.layer.removeAllAnimations()
    }
    
    /// 이미지 전환 애니메이션 (첫 번째 → 두 번째 페이지만)
    private func transitionToNewImage(_ newImageName: String) {
        UIView.animate(withDuration: 0.2, animations: {
            self.imageView.alpha = 0.0
        }) { _ in
            self.imageView.image = UIImage(named: newImageName)
            UIView.animate(withDuration: 0.2) {
                self.imageView.alpha = 1.0
            }
        }
    }
    
    // MARK: - UI 업데이트
    private func updateUI(state: OnboardingState) {
        let data = onboardingData[state.currentPage]
        let currentPage = state.currentPage
        
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
        } completion: { _ in
            // 레이아웃 완료 후 애니메이션 시작
            self.setupFloatingAnimation()
        }
        
        // 첫 번째 → 두 번째 페이지 이동 시에만 페이드 애니메이션 적용
        if previousPage == 0 && currentPage == 1 {
            transitionToNewImage(data.image)
        } else {
            // 다른 페이지 전환은 즉시 이미지 변경
            imageView.image = UIImage(named: data.image)
        }
        previousPage = currentPage  // 이전 페이지 업데이트
        
        pageControl.setCurrentPage(state.currentPage, animated: true)
        let isLast = state.currentPage == onboardingData.count - 1
        actionButton.updateProceed(isFinalStep: isLast)
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
    
    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.updateUI(state: state)
        }
        viewModel.onComplete = { [weak self] in
            self?.completeOnboardingAndGoToLogin()
        }
    }
    
    // MARK: - 온보딩 완료 처리
    private func completeOnboardingAndGoToLogin() {
        stopCurrentAnimation() // 애니메이션 정리
        UserDefaults.standard.set(true, forKey: "hasOnboarded")
        let loginVC = DIContainer.shared.makeLoginViewController()
        
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
