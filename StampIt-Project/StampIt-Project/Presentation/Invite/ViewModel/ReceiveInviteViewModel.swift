//
//  ReceiveInviteViewModel.swift
//  StampIt-Project
//
//  Created by 윤주형 on 6/9/25.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseFirestore
import FirebaseAuth

/// 그룹 초대 코드 입력 화면 viewModel
final class ReceiveInviteViewModel: ViewModelProtocol {

    // MARK: - Action & State

    enum Action {
        case codeChanged(String)
        case enterButtonTapped
    }

    struct State {
        let inviteCode = BehaviorRelay<String>(value: "")
        let isEnterButtonEnabled = BehaviorRelay<Bool>(value: false)
        let showMessage = PublishRelay<String>()
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    let state = State()
    private let firestoreManager = FirestoreManager.shared
    
    // Mock 데이터
    private let mockUser = UserFirestore(
        userId: "testUser004",
        nickname: "테스트유저004",
        email: "test004@example.com",
        profileImage: nil,
        groupId: "",
        nicknameChangedAt: Timestamp(),
        createdAt: Timestamp()
    )

    // MARK: - Init
    init() {
        bindActions()
    }

    // MARK: - Bind

    private func bindActions() {
        action
            .subscribe(onNext: { [weak self] action in
                guard let self = self else { return }
                
                switch action {
                case .codeChanged(let code):
                    self.state.inviteCode.accept(code)
                    self.state.isEnterButtonEnabled.accept(!code.isEmpty)
                    
                case .enterButtonTapped:
                    let inviteCode = self.state.inviteCode.value
                    
                    // 초대장 조회
                    self.firestoreManager.fetchInvite(inviteCode: inviteCode)
                        .flatMap { [weak self] invite -> Observable<Void> in
                            guard let self = self else { return .empty() }
                            
                            // 새 멤버 생성 (Mock 데이터 사용)
                            let newMember = MemberFirestore(
                                userId: self.mockUser.userId,
                                nickname: self.mockUser.nickname,
                                joinedAt: Timestamp(),
                                isLeader: false
                            )
                            
                            // 초대장의 그룹 ID로 멤버 추가
                            return self.firestoreManager.addMember(groupId: invite.groupId, member: newMember)
                        }
                        .subscribe(onNext: { [weak self] _ in
                            self?.state.showMessage.accept("그룹에 성공적으로 참여했습니다!")
                        }, onError: { [weak self] error in
                            self?.state.showMessage.accept("초대 코드 처리 실패: \(error.localizedDescription)")
                        })
                        .disposed(by: self.disposeBag)
                }
            })
            .disposed(by: disposeBag)
    }
}
