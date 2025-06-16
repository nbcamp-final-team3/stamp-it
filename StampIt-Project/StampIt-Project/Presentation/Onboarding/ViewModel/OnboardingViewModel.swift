//
//  OnboardingViewModel.swift
//  StampIt-Project
//
//  Created by iOS study on 6/14/25.
//

import Foundation
import RxSwift
import RxRelay

// MARK: - Action
/// 온보딩 화면에서 발생할 수 있는 사용자 액션들을 정의
enum OnboardingAction {
    case nextPage   // 다음 페이지로 이동
    case skip       // 온보딩 건너뛰기
    case complete   // 온보딩 완료
}

// MARK: - State
/// 온보딩 화면의 현재 상태를 나타내는 구조체
struct OnboardingState {
    var currentPage: Int    // 현재 페이지 인덱스
    let totalPages: Int     // 전체 페이지 수
    var isCompleted: Bool   // 온보딩 완료 여부
}

// MARK: - ViewModel
/// 온보딩 화면의 비즈니스 로직을 담당하는 뷰모델
final class OnboardingViewModel: ViewModelProtocol {
    typealias Action = OnboardingAction
    typealias State = OnboardingState

    // MARK: - Properties
    let disposeBag = DisposeBag()
    let action = PublishRelay<OnboardingAction>()
    private(set) var state: OnboardingState

    /// 상태 변화 콜백 (VC에서 바인딩)
    var onStateChange: ((OnboardingState) -> Void)?
    /// 온보딩 완료시 콜백 (VC에서 화면전환 등에 사용)
    var onComplete: (() -> Void)?

    // MARK: - Init
    init(totalPages: Int) {
        self.state = OnboardingState(currentPage: 0, totalPages: totalPages, isCompleted: false)
        bindAction()
    }

    // MARK: - Public Methods
    /// 액션을 뷰모델에 전달
    func send(_ action: OnboardingAction) {
        self.action.accept(action)
    }

    // MARK: - Private Methods
    /// 액션 스트림을 바인딩하여 상태 변화를 처리
    private func bindAction() {
        action
            .subscribe(onNext: { [weak self] action in
                guard let self = self else { return }
                switch action {
                case .nextPage:
                    if self.state.currentPage < self.state.totalPages - 1 {
                        self.state.currentPage += 1
                        self.onStateChange?(self.state)
                    } else {
                        self.send(.complete)
                    }
                case .skip, .complete:
                    self.state.isCompleted = true
                    self.onStateChange?(self.state)
                    self.onComplete?()
                }
            })
            .disposed(by: disposeBag)
    }
}
