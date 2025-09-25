//
//  SendInviteViewController.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/7/25.
//

import Foundation
import UIKit
import Then
import SnapKit
import RxSwift

final class SendInviteViewController: UIViewController{

    // MARK: - Properties
    private let viewModel: SendInviteViewModel
    private let disposeBag = DisposeBag()

    // MARK: - Init
    init(viewModel: SendInviteViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    private let navigationBar = DefaultNavigationBar(.titleWithBackButton(title: "초대하기"))

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let imageView = UIImageView().then {
        $0.image = UIImage(named: "MascotCharacter")
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
    }

    private let helpLabel = UILabel().then {
        $0.text = "초대할 멤버에게 아래 코드를 전달해주세요"
        $0.font = .pretendard(size: 16, weight: .regular)
    }

    private let textFieldInTitle = UILabel().then {
        $0.text = "초대코드"
        $0.font = .pretendard(size: 16, weight: .regular)
        $0.textColor = .gray800
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    private let inviteCodeLabel = UILabel().then {
        $0.font = .pretendard(size: 16, weight: .bold)
        $0.textColor = .gray800
        $0.numberOfLines = 1
        $0.lineBreakMode = .byTruncatingTail
    }

    private let shareButton = UIButton(type: .system).then {
        $0.setImage(UIImage(named: "ContentShare"), for: .normal)
        $0.tintColor = .gray500
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    private let inviteCodeStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 12
        $0.alignment = .center
        $0.backgroundColor = UIColor.F_2_F_2_F_2
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
        $0.layer.cornerRadius = 12
    }

    private let stackViewContainerView = UIView().then {
        $0.backgroundColor = .clear
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .FFFFFF
        setupLayout()
        bindViewModel()
        setupNavigation()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.tabBar.isHidden = false
    }

    private func setupNavigation() {
        navigationController?.navigationBar.isHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    private func setupLayout() {

        [navigationBar, imageView, helpLabel, stackViewContainerView]
            .forEach{ view.addSubview($0) }

        [textFieldInTitle, inviteCodeLabel, shareButton]
            .forEach { inviteCodeStackView.addArrangedSubview($0) }

        [textFieldInTitle, inviteCodeLabel].forEach {
            $0.setContentCompressionResistancePriority(.required, for: .vertical)
            $0.setContentHuggingPriority(.required, for: .vertical)
        }

        [inviteCodeStackView]
            .forEach { stackViewContainerView.addSubview($0) }


        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.directionalHorizontalEdges.equalToSuperview()
        }

        imageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(100)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(30)
            $0.top.equalTo(navigationBar.snp.bottom).offset(140)
        }

        helpLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(imageView.snp.bottom).offset(20)
        }

        stackViewContainerView.snp.makeConstraints {
            $0.top.equalTo(helpLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(72)
        }

        inviteCodeStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        textFieldInTitle.snp.makeConstraints {
            $0.width.equalTo(60)
        }

        shareButton.snp.makeConstraints {
            $0.width.height.equalTo(24)
        }
    }

    // MARK: - Bind
    private func bindViewModel() {
        // 데이터 바인딩
        bindInviteCode()
        bindShareAction()
        bindNavigation()
        bindMessages()
    }

    private func bindInviteCode() {
        viewModel.state.inviteCode
            .bind(to: inviteCodeLabel.rx.text)
            .disposed(by: disposeBag)
    }

    private func bindShareAction() {
        shareButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showShareActivity()
            })
            .disposed(by: disposeBag)
    }



    private func bindNavigation() {
        navigationBar.backTapped
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
    }

    private func bindMessages() {
        viewModel.state.showMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (type, message) in
                guard let self = self else { return }

                let toastView = ToastView()
                toastView.show(in: self.view, message: message, type: type)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        let message = error.localizedDescription
        viewModel.state.showMessage.accept((.failure, message))
    }
    
    // MARK: - Share Methods
    private func showShareActivity() {
        let code = viewModel.state.inviteCode.value
        let currentUser = viewModel.state.currentUser.value
        let userNickname = currentUser?.nickname ?? "사용자"
        
        // 딥링크 URL 생성 (앱 설치된 사용자용)
        let deepLink = DeepLink.invite(code)
        let deepLinkURL = deepLink.url
        
        // 앱스토어 URL (앱 미설치 사용자용)
        let appStoreURL = "https://apps.apple.com/kr/app/stamp-it/id6747178558"
        
        // 공유할 텍스트 생성
        let shareText = """
        \(userNickname)님이 미션으로 함께하는 공동체 생활, Stamp it에 초대했습니다.

        지금 초대에 수락해 함께 즐거운 공동체 생활을 시작해보세요

        초대 코드: \(code)
        
        앱으로 입장하기: \(deepLinkURL?.absoluteString ?? "링크 생성 불가!")
        
        """
        
        // 공유할 아이템 배열 생성
        var items: [Any] = [shareText]
        
        // 앱스토어 URL 추가 (앱 미설치 사용자용)
        items.append(appStoreURL)

        // UIActivityViewController 생성 및 설정
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // 공유할 수 없는 앱 제외
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks,
            .markupAsPDF
        ]
        
        // 공유 완료 후 피드백
        activityViewController.completionWithItemsHandler = { [weak self] (activityType, completed, returnedItems, error) in
            if completed {
                DispatchQueue.main.async {
                    let toastView = ToastView()
                    toastView.show(in: self?.view ?? UIView(), message: "초대 코드가 공유되었습니다", type: .success)
                }
            }
        }
        
        // 공유 시트 표시
        present(activityViewController, animated: true, completion: nil)
    }
}

    // MARK: - UINavigationControllerDelegate

extension SendInviteViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    // navigationController의 viewControllers가 2개 이상일 때만 pop 허용
    return navigationController?.viewControllers.count ?? 0 > 1
  }
}



