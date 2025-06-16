//
//  LoginViewModel.swift
//  StampIt-Project
//
//  Created by iOS study on 6/11/25.
//

import Foundation
import RxSwift

// MARK: - Login Action
/// 로그인 화면에서 발생하는 액션(이벤트) 정의
enum LoginAction {
    case viewDidLoad
    case googleLoginTapped
    case appleLoginTapped
    case retryLogin
}

// MARK: - Login State
/// 로그인 화면의 상태를 담는 구조체
struct LoginState {
    let isLoading: Bool
    let loginType: LoginType?
    let user: User?
    let isNewUser: Bool
    let nextAction: LoginNextAction?
    let error: String?
    
    /// 초기 상태값
    static let initial = LoginState(
        isLoading: false,
        loginType: nil,
        user: nil,
        isNewUser: false,
        nextAction: nil,
        error: nil
    )
}

// MARK: - Login Type
/// 로그인 방식(구글/애플) 구분
enum LoginType {
    case google
    case apple
    
    /// UI에 표시될 로그인 타입 이름
    var displayName: String {
        switch self {
        case .google: return "구글"
        case .apple: return "애플"
        }
    }
}

// MARK: - Login ViewModel
/// 로그인 화면 전용 ViewModel (Action-State 패턴)
final class LoginViewModel {
    
    // MARK: - Properties
    private let loginUseCase: LoginUseCaseProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs (Actions)
    /// View에서 발생하는 액션을 전달받는 Subject
    private let actionSubject = PublishSubject<LoginAction>()
    
    // MARK: - Outputs (State)
    /// View에 전달할 상태를 관리하는 BehaviorSubject
    private let stateSubject = BehaviorSubject<LoginState>(value: .initial)
    
    /// View에서 구독하는 상태 Observable
    var state: Observable<LoginState> {
        return stateSubject.asObservable()
    }
    
    // MARK: - Convenience State Properties
    /// 로딩 상태만 따로 구독할 때 사용
    var isLoading: Observable<Bool> {
        return state.map { $0.isLoading }.distinctUntilChanged()
    }
    
    /// 현재 로그인 타입만 구독할 때 사용
    var loginType: Observable<LoginType?> {
        return state.map { $0.loginType }.distinctUntilChanged()
    }
    
    /// 로그인 성공 시 유저, 신규여부, 다음 액션을 한 번에 구독
    var loginResult: Observable<(User, Bool, LoginNextAction)?> {
        return state
            .compactMap { state in
                guard let user = state.user, let nextAction = state.nextAction else { return nil }
                return (user, state.isNewUser, nextAction)
            }
    }
    
    /// 에러 메시지만 구독
    var errorMessage: Observable<String?> {
        return state.compactMap { $0.error }
    }
    
    /// 로딩 메시지 (ex: "구글 로그인 중...")
    var loadingMessage: Observable<String> {
        return Observable.combineLatest(isLoading, loginType) { isLoading, loginType in
            guard isLoading, let type = loginType else { return "" }
            return "\(type.displayName) 로그인 중..."
        }
    }
    
    // MARK: - Init
    /// ViewModel 생성자
    init(loginUseCase: LoginUseCaseProtocol) {
        self.loginUseCase = loginUseCase
        bindActions()
    }
    
    // MARK: - Public Methods
    /// View에서 액션을 전달할 때 사용
    func send(action: LoginAction) {
        actionSubject.onNext(action)
    }
    
    // MARK: - Private Methods
    /// 액션 Subject 바인딩 및 처리
    private func bindActions() {
        actionSubject
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] action in
                self?.handleAction(action)
            })
            .disposed(by: disposeBag)
    }
    
    /// 각 액션별로 동작 분기
    private func handleAction(_ action: LoginAction) {
        switch action {
        case .viewDidLoad:
            // 초기 상태 설정 (필요시)
            break
            
        case .googleLoginTapped:
            performLogin(type: .google)
            
        case .appleLoginTapped:
            performLogin(type: .apple)
            
        case .retryLogin:
            if let currentState = try? stateSubject.value(),
               let currentLoginType = currentState.loginType {
                performLogin(type: currentLoginType)
            }
        }
    }
    
    /// 실제 로그인 UseCase 실행
    private func performLogin(type: LoginType) {
        // 로딩 시작 상태로 갱신
        updateState { state in
            LoginState(
                isLoading: true,
                loginType: type,
                user: state.user,
                isNewUser: state.isNewUser,
                nextAction: state.nextAction,
                error: nil
            )
        }
        
        let loginObservable: Observable<LoginFlowResult>
        
        switch type {
        case .google:
            loginObservable = loginUseCase.loginWithGoogle()
        case .apple:
            loginObservable = loginUseCase.loginWithApple()
        }
        
        loginObservable
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] result in
                    self?.updateState { state in
                        LoginState(
                            isLoading: false,
                            loginType: state.loginType,
                            user: result.user,
                            isNewUser: result.isNewUser,
                            nextAction: result.nextAction,
                            error: nil
                        )
                    }
                },
                onError: { [weak self] error in
                    self?.updateState { state in
                        LoginState(
                            isLoading: false,
                            loginType: state.loginType,
                            user: state.user,
                            isNewUser: state.isNewUser,
                            nextAction: state.nextAction,
                            error: self?.formatErrorMessage(error, loginType: type)
                        )
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// 에러 메시지 포맷팅
    private func formatErrorMessage(_ error: Error, loginType: LoginType) -> String {
        if let useCaseError = error as? UseCaseError {
            switch useCaseError {
            case .authenticationFailed(let message):
                return "\(loginType.displayName) 로그인에 실패했습니다: \(message)"
            case .networkFailed(let message):
                return "네트워크 오류: \(message)"
            case .processingFailed(let message):
                return "처리 중 오류: \(message)"
            default:
                return "\(loginType.displayName) 로그인 중 오류가 발생했습니다"
            }
        } else {
            return "\(loginType.displayName) 로그인 중 알 수 없는 오류가 발생했습니다"
        }
    }
    
    /// 상태 Subject 값 갱신 헬퍼
    private func updateState(_ transform: (LoginState) -> LoginState) {
        do {
            let currentState = try stateSubject.value()
            let newState = transform(currentState)
            stateSubject.onNext(newState)
        } catch {
            print("❌ State update failed: \(error)")
        }
    }
}
