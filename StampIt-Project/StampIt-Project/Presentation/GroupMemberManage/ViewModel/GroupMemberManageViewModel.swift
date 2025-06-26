//
//  GroupMemberManageViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/15/25.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

final class GroupMemberManageViewModel: ViewModelProtocol {

    // MARK: - Dependencies
    private let groupManageUseCase: GroupManageUseCase
    
    // MARK: - Action & State

    enum Action {
        case didTapCardOptionButton(memberId: String)
        case didReceiveMemberManageType(MemberManageOptionType, memberId: String)
        case viewDidLoad
    }

    struct State {
        let isLeader = BehaviorRelay<Bool>(value: false)
        let showOptionSheet = PublishRelay<String>()
        let showSuccess = PublishRelay<String>()
        let showToast = PublishRelay<String>()
        let isLoading = BehaviorRelay<Bool>(value: false)
        let members = BehaviorRelay<[Member]>(value: [])
        let shouldRefreshMembers = PublishRelay<Void>()
    }

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()
    
    private var currentGroupId: String = ""
    private var currentUserId: String = ""

    init(groupManageUseCase: GroupManageUseCase) {
        self.groupManageUseCase = groupManageUseCase
        bindActions()
    }

    private func bindActions() {
        // Action과 State 바인딩 구현
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .viewDidLoad:
                    owner.loadInitialData()
                case .didTapCardOptionButton(let memberId):
                    owner.handleOptionButtonTap(memberId: memberId)
                case .didReceiveMemberManageType(let type, let memberId):
                    owner.handleMemberState(type: type, memberId: memberId)
                }
            }.disposed(by: disposeBag)
        
        // 멤버 목록 새로고침 시그널 바인딩
        state.shouldRefreshMembers
            .subscribe(with: self) { owner, _ in
                owner.refreshMembers()
            }
            .disposed(by: disposeBag)
    }
    
    private func loadInitialData() {
        state.isLoading.accept(true)
        
        groupManageUseCase.getCurrentUser()
            .flatMap { [weak self] optionalUser -> Observable<(User, [Member])> in
                guard let self = self, let user = optionalUser else {
                    return Observable.error(RepositoryError.userNotFound)
                }
                
                self.currentGroupId = user.groupID
                self.currentUserId = user.userID
                self.state.isLeader.accept(user.isLeader)
                
                return self.groupManageUseCase.fetchGroupMembers(groupId: user.groupID)
                    .map { members in (user, members) }
            }
            .subscribe(with: self) { owner, userAndMembers in
                let (_, members) = userAndMembers
                owner.state.members.accept(members)
                owner.state.isLoading.accept(false)
            } onError: { owner, error in
                let errorMessage = owner.getToastMessage(from: error)
                owner.state.showToast.accept(errorMessage)
                owner.state.isLoading.accept(false)
            }
            .disposed(by: disposeBag)
    }

    private func handleMemberState(type: MemberManageOptionType, memberId: String) {
        state.isLoading.accept(true)
        
        let operation: Observable<Void>
        
        switch type {
        case .leaderMandate:
            operation = groupManageUseCase.delegateLeader(to: memberId)
        case .exportMember:
            // memberId로 Member를 찾고 User로 변환
            let member = state.members.value.first { $0.userID == memberId }
            guard let targetMember = member else {
                state.showToast.accept("멤버를 찾을 수 없습니다.")
                state.isLoading.accept(false)
                return
            }
            
            // 현재 사용자 정보에서 그룹 정보 가져오기
            groupManageUseCase.getCurrentUser()
                .flatMap { [weak self] optionalUser -> Observable<User> in
                    guard let self = self, let currentUser = optionalUser else {
                        return Observable.error(RepositoryError.userNotFound)
                    }
                    
                    // Member를 User로 변환
                    let targetUser = targetMember.toUser(
                        groupId: currentUser.groupID,
                        groupName: currentUser.groupName
                    )
                    
                    return self.groupManageUseCase.exportMember(member: targetUser)
                }
                .subscribe(with: self) { owner, exportedUser in
                    owner.state.showSuccess.accept("멤버가 내보내졌습니다.")
                    owner.state.isLoading.accept(false)
                    owner.state.shouldRefreshMembers.accept(())
                } onError: { owner, error in
                    let errorMessage = owner.getToastMessage(from: error)
                    owner.state.showToast.accept(errorMessage)
                    owner.state.isLoading.accept(false)
                }
                .disposed(by: disposeBag)
            return
        }
        
        operation
            .subscribe(with: self) { owner, _ in
                let message = type == .leaderMandate ? "리더 위임이 완료되었습니다." : "멤버가 내보내졌습니다."
                owner.state.showSuccess.accept(message)
                owner.state.isLoading.accept(false)
                
                // 리더 위임인 경우 isLeader 상태를 false로 변경
                if type == .leaderMandate {
                    owner.state.isLeader.accept(false)
                }
                
                // 멤버 목록 새로고침 시그널 emit
                owner.state.shouldRefreshMembers.accept(())
            } onError: { owner, error in
                let errorMessage = owner.getToastMessage(from: error)
                owner.state.showToast.accept(errorMessage)
                owner.state.isLoading.accept(false)
            }
            .disposed(by: disposeBag)
    }
    
    private func refreshMembers() {
        groupManageUseCase.fetchGroupMembers(groupId: currentGroupId)
            .subscribe(with: self) { owner, members in
                owner.state.members.accept(members)
            } onError: { owner, error in
                let errorMessage = owner.getToastMessage(from: error)
                owner.state.showToast.accept(errorMessage)
            }
            .disposed(by: disposeBag)
    }

    private func handleOptionButtonTap(memberId: String) {
        // 현재 사용자가 리더인지 확인
        if state.isLeader.value {
            // 리더인 경우 옵션 시트 표시
            state.showOptionSheet.accept(memberId)
        } else {
            // 리더가 아닌 경우 토스트 메시지 표시
            state.showToast.accept("리더만 사용 가능합니다.")
        }
    }

    /// 에러를 토스트 메시지로 변환하는 헬퍼 메서드
    private func getToastMessage(from error: Error) -> String {
        // GroupUseCaseError 처리
        if let groupUseCaseError = error as? GroupUseCaseError {
            return groupUseCaseError.toastMessage
        }
        
        // RepositoryError 처리
        if let repositoryError = error as? RepositoryError {
            return repositoryError.toastMessage
        }
        
        // 기타 에러는 기본 메시지 반환
        return error.localizedDescription
    }
    
    /// 현재 사용자 ID 가져오기
    func getCurrentUserId() -> String {
        return currentUserId
    }
}

extension GroupMemberManageViewModel {
    enum Section {
        case main
    }

    struct Item: Hashable {
        let id: String
        let name: String
        let date: String
        let image: UIImage?
        let isCurrentUser: Bool
    }
}
