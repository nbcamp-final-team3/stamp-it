//
//  LoginUseCaseImpl.swift
//  StampIt-Project
//
//  Created by iOS study on 6/11/25.
//

import Foundation
import RxSwift
import CryptoKit
import FirebaseCore

// MARK: - LoginUseCase Implementation
final class LoginUseCase: LoginUseCaseProtocol {
    
    // MARK: - Properties
    private let authRepository: AuthRepositoryProtocol
    private let randomNicknameProvider: (String) -> String
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(authRepository: AuthRepositoryProtocol,
         randomNicknameProvider: @escaping (String) -> String = LoginUseCase.generateSecureUniqueNickname) {
        self.authRepository = authRepository
        self.randomNicknameProvider = randomNicknameProvider
    }
    
    // MARK: - Login Methods
    /// 구글 로그인 플로우
    func loginWithGoogle() -> Observable<LoginFlowResult> {
        return authRepository.signInWithGoogle()
            .flatMap { [weak self] loginResult -> Observable<LoginFlowResult> in
                self?.processLoginResult(loginResult) ?? Observable.error(UseCaseError.unknownError)
            }
            .catch { [weak self] error in
                let useCaseError = self?.mapToUseCaseError(error) ?? UseCaseError.unknownError
                return Observable.error(useCaseError)
            }
    }
    
    /// 애플 로그인 플로우 (준비)
    func loginWithApple() -> Observable<LoginFlowResult> {
        return authRepository.signInWithApple()
            .flatMap { [weak self] loginResult -> Observable<LoginFlowResult> in
                self?.processLoginResult(loginResult) ?? Observable.error(UseCaseError.unknownError)
            }
            .catch { [weak self] error in
                let useCaseError = self?.mapToUseCaseError(error) ?? UseCaseError.unknownError
                return Observable.error(useCaseError)
            }
    }
    
    // MARK: - Launch State Check
    /// 앱 시작 시 상태 확인 및 화면 분기 결정
    func checkLaunchState() -> Observable<LaunchFlowResult> {
        return authRepository.checkLaunchState()
            .map { launchResult in
                if !launchResult.isAuthenticated {
                    // 미로그인 상태
                    let nextScreen: LaunchNextScreen = launchResult.needsOnboarding ? .onboarding : .login
                    return LaunchFlowResult(nextScreen: nextScreen, user: nil)
                } else {
                    // 로그인된 상태 → 메인으로
                    return LaunchFlowResult(nextScreen: .main, user: launchResult.user)
                }
            }
            .catch { _ in
                // 에러 발생 시 로그인 화면으로 안전하게 분기
                return Observable.just(LaunchFlowResult(nextScreen: .login, user: nil))
            }
    }

    // MARK: - Private Methods
    /// 로그인 결과 공통 처리 로직 (중복 제거)
    private func processLoginResult(_ loginResult: LoginResult) -> Observable<LoginFlowResult> {
        if loginResult.isNewUser {
            // 신규 사용자: AuthUser에서 userID 추출
            guard let authUser = loginResult.authUser else {
                return Observable.error(UseCaseError.processingFailed("신규 사용자 정보가 없습니다"))
            }
            return createNewUserWithAutoGroup(authUser: authUser)
        } else {
            // 기존 사용자: User에서 정보 추출
            guard let user = loginResult.user else {
                return Observable.error(UseCaseError.processingFailed("기존 사용자 정보가 없습니다"))
            }
            return Observable.just(LoginFlowResult(
                user: user,
                isNewUser: false,
                nextAction: .navigateToMain
            ))
        }
    }
    
    /// 신규 사용자 자동 그룹 생성 플로우
    private func createNewUserWithAutoGroup(authUser: AuthUser) -> Observable<LoginFlowResult> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(UseCaseError.unknownError)
                return Disposables.create()
            }
            
            let randomNickname = self.randomNicknameProvider(authUser.uid)
            let groupId = UUID().uuidString
            let now = Date()
            let inviteCode = self.generateInviteCode()
            
            // TODO: 디버깅용 로그, 삭제 예정
            print("🆕 신규 사용자 그룹 생성 시작")
            print("   - 사용자 ID: \(authUser.uid)")
            print("   - 닉네임: \(randomNickname)")
            print("   - 그룹 ID: \(groupId)")
            print("   - 초대코드: \(inviteCode)")
            
            let userFirestore = UserFirestore(
                userId: authUser.uid,
                nickname: randomNickname,
                profileImage: authUser.photoURL,
                groupId: groupId,
                nicknameChangedAt: Timestamp(date: now),
                createdAt: Timestamp(date: now)
            )
            
            let groupFirestore = GroupFirestore(
                groupId: groupId,
                name: "\(randomNickname)의 그룹",
                leaderId: authUser.uid,
                inviteCode: inviteCode,
                nameChangedAt: Timestamp(date: now),
                createdAt: Timestamp(date: now) 
            )
            
            let memberFirestore = MemberFirestore(
                userId: authUser.uid,
                nickname: randomNickname,
                joinedAt: Timestamp(date: now),
                isLeader: true
            )
            
            let inviteFirestore = InviteFirestore(
                inviteCode: inviteCode,
                groupId: groupId,
                createdBy: authUser.uid,
                createdAt: Timestamp(date: now),
                expiredAt: nil // 영구 초대 코드
            )
            
            // 3. 트랜잭션으로 원자적 생성
            self.authRepository.createNewUserWithGroup(
                user: userFirestore,
                group: groupFirestore,
                member: memberFirestore,
                invite: inviteFirestore
            )
            .subscribe(
                onNext: { completeUser in
                    observer.onNext(LoginFlowResult(
                        user: completeUser,
                        isNewUser: true,
                        nextAction: .showWelcomeMessage
                    ))
                    observer.onCompleted()
                },
                onError: { error in
                    observer.onError(UseCaseError.processingFailed("신규 사용자 생성 실패: \(error.localizedDescription)"))
                }
            )
            .disposed(by: self.disposeBag)
            
            return Disposables.create()
        }
    }
    
   /// 랜덤 닉네임 생성 (랜덤 닉네임+닉네임ID 해시값 4자리 묶어서 출력, 예시:  행복한 사자-742A1B2)
    static func generateSecureUniqueNickname(userID: String) -> String {
        let adjectives = ["행복한", "즐거운", "활발한", "따뜻한", "밝은"]
        let nouns = ["사자", "호랑이", "곰", "토끼", "고양이"]
        
        let randomAdjective = adjectives.randomElement() ?? "행복한"
        let randomNoun = nouns.randomElement() ?? "사자"
        
        // SHA256 해싱 후 4자리 추출
        let hashedID = userID.sha256.suffix(4)
        let randomNumber = Int.random(in: 100...999)
        
        return "\(randomAdjective) \(randomNoun)-\(randomNumber)\(hashedID)"
    }

    
    /// 초대 코드 생성 헬퍼 ( 동기적 생성, UUID 기반으로 중복 불가 8자리 코드)
    private func generateInviteCode() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String(uuid.prefix(8)).uppercased()
    }
    
    /// Repository 에러를 UseCase 에러로 매핑
    private func mapToUseCaseError(_ error: Error) -> UseCaseError {
        if let repositoryError = error as? RepositoryError {
            switch repositoryError {
            case .authenticationFailed(let message):
                return .authenticationFailed(message)
            case .userNotFound:
                return .userNotFound
            case .userNotInGroup:
                return .processingFailed("그룹 정보를 찾을 수 없습니다")
            case .dataError(let message):
                return .dataProcessingFailed(message)
            case .networkError(let message):
                return .networkFailed(message)
            case .uiError(let message):
                return .uiFailed(message)
            case .unknownError:
                return .unknownError
            }
        } else {
            return .unknownError
        }
    }
}
