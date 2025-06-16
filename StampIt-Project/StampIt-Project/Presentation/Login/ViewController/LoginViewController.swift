//
//  LoginViewController.swift
//  StampIt-Project
//
//  Created by iOS study on 6/11/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then
import AuthenticationServices

final class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: LoginViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Components
    /// 메인 스크롤뷰 (키보드 대응)
    private let scrollView = UIScrollView().then {
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.backgroundColor = .systemBackground
    }
    
    /// 컨텐츠 컨테이너
    private let contentView = UIView()
    
    /// 상단 타이틀 라벨
    private let topTitleLabel = UILabel().then {
        $0.text = "미션으로 함께하는 집안일"
        $0.font = .pretendard(size: 16, weight: .medium)
        $0.textColor = .label
        $0.textAlignment = .center
        $0.numberOfLines = 1
    }
    
    /// 메인 로고 이미지뷰 (Stamp it)
    private let logoImageView = UIImageView().then {
        $0.image = UIImage(named: "AppLogo")
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .clear
    }
    
    /// 하단 로그인 섹션 컨테이너
    private let loginSectionView = UIView()
    
    /// 로그인 버튼들을 담는 스택뷰
    private let loginButtonStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
        $0.distribution = .fillEqually
        $0.alignment = .fill
    }
    
    /// Apple 로그인 버튼 (HIG 준수)
    private let appleLoginButton = ASAuthorizationAppleIDButton(
        authorizationButtonType: .signIn,
        authorizationButtonStyle: .black
    ).then {
        $0.cornerRadius = 8
    }
    
    /// Google 로그인 버튼 (구글 제공 이미지 사용)
    private lazy var googleLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 218/255, green: 220/255, blue: 224/255, alpha: 1).cgColor // 공식 가이드 연회색
        button.clipsToBounds = true

        let title = "Sign in with Google"
        let font = UIFont.systemFont(ofSize: 16, weight: .medium)

        let googleLogo = UIImage(named: "GoogleLogo")
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = googleLogo
        imageAttachment.bounds = CGRect(x: 0, y: -2, width: 20, height: 20)

        let fullString = NSMutableAttributedString()
        fullString.append(NSAttributedString(attachment: imageAttachment))
        // 10pt 간격
        let space = NSAttributedString(string: "\u{200A}", attributes: [.font: font, .kern: 10])
        fullString.append(space)
        fullString.append(NSAttributedString(string: title, attributes: [
            .font: font,
            .foregroundColor: UIColor.black
        ]))
        button.setAttributedTitle(fullString, for: .normal)

        button.setImage(nil, for: .normal)
        button.accessibilityLabel = "구글로 로그인하기"
        return button
    }()
    
    /// 로딩 컨테이너 (최하단에 배치)
    private let loadingContainerView = UIView().then {
        $0.backgroundColor = .clear
        $0.isHidden = true
    }
    
    /// 로딩 인디케이터
    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
        $0.color = .systemGray
    }
    
    /// 로딩 메시지 라벨
    private let loadingMessageLabel = UILabel().then {
        $0.font = .pretendard(size: 14, weight: .medium)
        $0.textColor = .systemGray
        $0.textAlignment = .center
        $0.numberOfLines = 1
    }
    
    // MARK: - Init
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.send(action: .viewDidLoad)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 뷰 계층 구성
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // 메인 뷰들 추가
        [topTitleLabel, logoImageView, loginSectionView, loadingContainerView].forEach {
            contentView.addSubview($0)
        }
        
        // 로그인 섹션 구성
        loginSectionView.addSubview(loginButtonStackView)
        
        // 로딩 컨테이너 구성
        [loadingIndicator, loadingMessageLabel].forEach {
            loadingContainerView.addSubview($0)
        }
        
        // Apple 로그인 버튼을 스택뷰에 먼저 추가 (HIG: Apple 로그인이 있으면 최상단 배치)
        loginButtonStackView.addArrangedSubview(appleLoginButton)
        loginButtonStackView.addArrangedSubview(googleLoginButton)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        // 스크롤뷰 제약조건
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 컨텐츠뷰 제약조건 (수정)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(view.safeAreaLayoutGuide).priority(.low)
        }
        
        // 상단 타이틀 라벨 제약조건
        topTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(230)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        // 메인 로고 이미지뷰 제약조건
        logoImageView.snp.makeConstraints { make in
            make.top.equalTo(topTitleLabel.snp.bottom).offset(15)
            make.centerX.equalToSuperview()
            make.width.equalTo(240)
            make.height.equalTo(70)
        }
        
        // 로그인 섹션 제약조건
        loginSectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(logoImageView.snp.bottom).offset(100)
            make.height.equalTo(140)
        }
        
        // 로그인 버튼 스택뷰 제약조건
        loginButtonStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
            make.centerY.equalToSuperview()
        }
        
        // Apple 로그인 버튼 높이
        appleLoginButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        // Google 로그인 버튼 높이
        googleLoginButton.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        
        // 로딩 컨테이너 제약조건 (최하단)
        loadingContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(60)
        }
        
        // 로딩 인디케이터 제약조건
        loadingIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(8)
        }
        
        // 로딩 메시지 라벨 제약조건
        loadingMessageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(loadingIndicator.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    // MARK: - Bind ViewModel
    private func bindViewModel() {
        // MARK: - Inputs (View -> ViewModel)
        
        // Apple 로그인 버튼 탭
        appleLoginButton.rx.controlEvent(.touchUpInside)
            .map { LoginAction.appleLoginTapped }
            .subscribe(onNext: { [weak self] action in
                self?.viewModel.send(action: action)
            })
            .disposed(by: disposeBag)
        
        // Google 로그인 버튼 탭
        googleLoginButton.rx.tap
            .map { LoginAction.googleLoginTapped }
            .subscribe(onNext: { [weak self] action in
                self?.viewModel.send(action: action)
            })
            .disposed(by: disposeBag)
        
        // MARK: - Outputs (ViewModel -> View)
        
        // 로딩 상태 바인딩
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            })
            .disposed(by: disposeBag)
        
        // 로딩 메시지 바인딩
        viewModel.loadingMessage
            .observe(on: MainScheduler.instance)
            .bind(to: loadingMessageLabel.rx.text)
            .disposed(by: disposeBag)
        
        // 로그인 성공 처리
        viewModel.loginResult
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (user, isNewUser, nextAction) in
                self?.handleLoginSuccess(user: user, isNewUser: isNewUser, nextAction: nextAction)
            })
            .disposed(by: disposeBag)
        
        // 에러 처리
        viewModel.errorMessage
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    /// 로딩 상태 UI 업데이트 (하단에 표시)
    private func updateLoadingState(_ isLoading: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            if isLoading {
                // 로딩 시작
                self?.loadingContainerView.isHidden = false
                self?.loadingContainerView.alpha = 1.0
                self?.loadingIndicator.startAnimating()
                
                // 버튼 비활성화
                self?.appleLoginButton.isEnabled = false
                self?.googleLoginButton.isEnabled = false
                self?.appleLoginButton.alpha = 0.6
                self?.googleLoginButton.alpha = 0.6
                
            } else {
                // 로딩 종료
                self?.loadingContainerView.alpha = 0.0
                self?.loadingIndicator.stopAnimating()
                
                // 버튼 활성화
                self?.appleLoginButton.isEnabled = true
                self?.googleLoginButton.isEnabled = true
                self?.appleLoginButton.alpha = 1.0
                self?.googleLoginButton.alpha = 1.0
            }
        } completion: { [weak self] _ in
            if !isLoading {
                self?.loadingContainerView.isHidden = true
            }
        }
    }
    
    /// 로그인 성공 처리
    private func handleLoginSuccess(user: User, isNewUser: Bool, nextAction: LoginNextAction) {
        // 성공 햅틱 피드백
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // 다음 화면으로 이동 처리
        switch nextAction {
        case .navigateToMain:
            navigateToHome(user: user)
        case .showWelcomeMessage:
            showWelcomeMessage(user: user)
        }
    }
    
    /// 홈 화면으로 이동
    private func navigateToHome(user: User) {
        // TODO: 홈 화면 ViewController로 이동 (홈화면 완전히 구성되면 작업 예정)
        print("✅ 홈 화면으로 이동: \(user.nickname)")
    }
    
    /// 신규 사용자 환영 메시지 표시
    private func showWelcomeMessage(user: User) {
        // TODO: 신규 사용자 환영 토스트 메시지로 변경 예정
        print("✅ 신규 사용자 환영: \(user.nickname)")
    }
    
    /// 에러 알림 표시
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "로그인 실패",
            message: message,
            preferredStyle: .alert
        )
        
        let confirmAction = UIAlertAction(title: "확인", style: .default)
        let retryAction = UIAlertAction(title: "다시 시도", style: .cancel) { [weak self] _ in
            self?.viewModel.send(action: .retryLogin)
        }
        
        alert.addAction(confirmAction)
        alert.addAction(retryAction)
        
        present(alert, animated: true)
    }
}
