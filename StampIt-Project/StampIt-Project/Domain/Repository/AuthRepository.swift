//
//  AuthRepository.swift
//  StampIt-Project
//
//  Created by iOS study on 6/10/25.
//

import Foundation
import RxSwift

protocol AuthRepositoryProtocol {
    // MARK: - 인증
    func signInWithGoogle() -> Observable<LoginResult>
    func signInWithApple() -> Observable<LoginResult>
    
    // MARK: - 그룹 조회 및 유저, 그룹 생성
    func fetchUserWithGroupInfo(userId: String) -> Observable<StampIt_Project.User>
    
    // MARK: - 개별 생성 메서드 노출 (SRP 준수)
    func createUser(_ user: UserFirestore) -> Observable<Void>
    func createGroup(_ group: GroupFirestore) -> Observable<Void>
    func addMember(groupId: String, member: MemberFirestore) -> Observable<Void>
    
    // MARK: - 상태 관리
    func getCurrentUser() -> Observable<StampIt_Project.User?>
    func observeAuthState() -> Observable<StampIt_Project.User?>
    func checkLaunchState() -> Observable<LaunchResult>
    
    // MARK: - 트랜잭션 보장 메서드 (원자성 보장)
    // 중간에 실패 시 앞 단계 데이터가 DB에 반영될 위험을 막기 위해 트랜잭션 추가함
    func createNewUserWithGroup(
        user: UserFirestore,
        group: GroupFirestore,
        member: MemberFirestore
    ) -> Observable<StampIt_Project.User>
}
