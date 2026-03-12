//
//  GroupMemberManageViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/15/25.
//

import Foundation
import RxSwift
import RxCocoa

final class GroupMemberManageViewModel: ViewModelProtocol {

    // MARK: - Dependencies
    private let groupManageUseCase: GroupManageUseCaseProtocol
    
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
        
        //State 업데이트 메서드 추가
        mutating func updateWithGroupData(_ data: GroupMemberLoadModel) {
            isLeader.accept(data.isLeader)
            members.accept(data.members)
            isLoading.accept(false)
        }
        
        mutating func setLoading(_ loading: Bool) {
            isLoading.accept(loading)
        }
        
        mutating func showError(_ message: String) {
            showToast.accept(message)
            isLoading.accept(false)
        }
    }

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()

    private var currentUserId: String = ""

    init(groupManageUseCase: GroupManageUseCaseProtocol) {
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
        state.setLoading(true)

        groupManageUseCase.loadGroupMemberManageData()
            .subscribe(with: self) { owner, data in
                owner.currentUserId = data.currentUser.userID
                owner.state.updateWithGroupData(data)
            } onError: { owner, error in
                let errorMessage = owner.getToastMessage(from: error)
                owner.state.showError(errorMessage)
            }
            .disposed(by: disposeBag)
    }

    private func handleMemberState(type: MemberManageOptionType, memberId: String) {
        state.setLoading(true)
        
        let operation: Observable<Void>
        
        switch type {
        case .leaderMandate:
            operation = groupManageUseCase.delegateLeader(to: memberId)
        case .exportMember:
            operation = groupManageUseCase.exportMember(memberId: memberId)
        }
        
        operation
            .subscribe(with: self) { owner, _ in
                let message = type == .leaderMandate ? "리더 위임이 완료되었습니다." : "멤버가 내보내졌습니다."
                owner.state.showSuccess.accept(message)
                owner.state.setLoading(false)
                
                // 리더 위임인 경우 isLeader 상태를 false로 변경
                if type == .leaderMandate {
                    owner.state.isLeader.accept(false)
                }
                
                // 멤버 목록 새로고침 시그널 emit
                owner.state.shouldRefreshMembers.accept(())
            } onError: { owner, error in
                let errorMessage = owner.getToastMessage(from: error)
                owner.state.showError(errorMessage)
            }
            .disposed(by: disposeBag)
    }
    
    private func refreshMembers() {
        groupManageUseCase.refreshMembers()
            .subscribe(with: self) { owner, members in
                owner.state.members.accept(members)
            } onError: { owner, error in
                let errorMessage = owner.getToastMessage(from: error)
                owner.state.showError(errorMessage)
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

    func createItems(from members: [Member]) -> [Item] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일"
        
        return members.map { member in
            let formattedDate = dateFormatter.string(from: member.joinedAt)
            
            return Item(
                id: member.userID,
                name: member.nickname,
                date: "그룹 가입일: \(formattedDate)",
                imageName: member.profileImage,  // 이미지 이름만 전달
                isCurrentUser: member.userID == currentUserId,
                isLeader: member.isLeader
            )
        }
    }
}

extension GroupMemberManageViewModel {
    enum Section {
        case main
    }

    // UIKit 의존성 제거
    struct Item: Hashable {
        let id: String
        let name: String
        let date: String
        let imageName: String?  // UIImage 대신 이미지 이름 사용
        let isCurrentUser: Bool
        let isLeader: Bool
    }
}
