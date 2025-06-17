//
//  AccountManageUseCaseImpl.swift
//  StampIt-Project
//
//  Created by iOS study on 6/17/25.
//

// TODO: print문은 리팩토링 단계에서 전체 예정
import Foundation
import RxSwift

final class AccountManageUseCase: AccountManageUseCaseProtocol {
    
    // MARK: - Properties
    private let authRepository: AuthRepositoryProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    // MARK: - Account Management
    
    /// 로그아웃
    func signOut() -> Observable<Void> {
        return authRepository.signOut()
            .do(onNext: {
                print("✅ 로그아웃 완료")
            })
            .catch { error in
                print("❌ 로그아웃 실패: \(error.localizedDescription)")
                return Observable.error(self.mapToUseCaseError(error))
            }
    }
    
    /// 계정 탈퇴
    func deleteAccount() -> Observable<Void> {
        return authRepository.deleteAccount()
            .do(onNext: {
                print("✅ 계정 탈퇴 완료")
            })
            .catch { error in
                print("❌ 계정 탈퇴 실패: \(error.localizedDescription)")
                return Observable.error(self.mapToUseCaseError(error))
            }
    }
    
    /// 그룹 탈퇴
    func leaveGroup() -> Observable<User> {
        return authRepository.leaveGroup()
            .do(onNext: { user in
                print("✅ 그룹 탈퇴 완료: \(user.groupName)")
            })
            .catch { error in
                print("❌ 그룹 탈퇴 실패: \(error.localizedDescription)")
                return Observable.error(self.mapToUseCaseError(error))
            }
    }
    
    /// 현재 사용자 정보 조회
    func getCurrentUser() -> Observable<User?> {
        return authRepository.getCurrentUser()
            .catch { error in
                print("❌ 사용자 정보 조회 실패: \(error.localizedDescription)")
                return Observable.just(nil)
            }
    }
    
    // MARK: - Private Methods
    
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
