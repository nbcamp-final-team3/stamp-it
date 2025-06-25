//
//  AccountManageUseCaseImpl.swift
//  StampIt-Project
//
//  Created by iOS study on 6/17/25.
//

import Foundation
import RxSwift

final class AccountManageUseCase: AccountManageUseCaseProtocol {
    
    // MARK: - Properties
    private let accountManageRepository: AccountManageRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(
        accountManageRepository: AccountManageRepositoryProtocol,
        authRepository: AuthRepositoryProtocol
    ) {
        self.accountManageRepository = accountManageRepository
        self.authRepository = authRepository
    }
    
    // MARK: - Account Management
    
    /// 로그아웃
    func signOut() -> Observable<Void> {
        return accountManageRepository.signOut()
    }
    
    /// 계정 탈퇴
    func deleteAccount() -> Observable<Void> {
        return accountManageRepository.deleteAccount()
    }
    
    /// 그룹 탈퇴
    func leaveGroup() -> Observable<User> {
        return accountManageRepository.leaveGroup()
    }
    
    /// 현재 사용자 정보 조회
    func getCurrentUser() -> Observable<User?> {
        return authRepository.getCurrentUser()
    }
    
    /// 그룹 멤버 수 조회
    func getGroupMemberCount(groupId: String) -> Observable<Int> {
        return accountManageRepository.getGroupMemberCount(groupId: groupId)
    }
}
