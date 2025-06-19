//
//  EditProfileViewModel.swift
//  StampIt-Project
//
//  Created by 권순욱 on 6/17/25.
//

import Foundation
import RxSwift
import RxRelay

final class EditProfileViewModel: ViewModelProtocol {
    enum Action {
        case onAppear
        case nicknameChanged(String)
        case groupNameChanged(String)
        case profileImageChanged(IndexPath)
        case didTapEditButton
    }
    
    struct State {
        var user = BehaviorRelay<User?>(value: nil)
        var isUserDataChanged = BehaviorRelay<Bool>(value: false)
    }
    
    var action = PublishRelay<Action>()
    var state = State()
    
    var disposeBag = DisposeBag()
    
    private let editProfileUseCaseImpl: EditProfileUseCase
    
    // 유저 정보(닉네임, 그룹명, 이미지)를 바꿀 때 임시 저장
    private var newNickname: String?
    private var newGroupName: String?
    private var newProfileImageName: String?
    
    // 유저 정보 중 하나라도 바뀌면 true
    // 임시 저장 변수(예: newNickname)가 nil이면 아직 바꾸려 시도하지 않은 것이므로 기존 정보와 동일하다고 가정
    private var isUserDataChanged: Bool {
        guard let user = state.user.value else { return false }
        return (newNickname ?? user.nickname) != user.nickname ||
               (newGroupName ?? user.groupName) != user.groupName ||
               (newProfileImageName ?? user.profileImageURL) != user.profileImageURL
    }
    
    init(user: User, editProfileUseCaseImpl: EditProfileUseCase) {
        state.user.accept(user)
        self.editProfileUseCaseImpl = editProfileUseCaseImpl
        
        bind()
    }
    
    deinit {
        print("editProfileViewModel deinit")
    }
    
    private func bind() {
        action
            .subscribe { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .onAppear:
                    print("on appear")
                case .nicknameChanged(let nickname):
                    print("nickname is changed: \(nickname)")
                    newNickname = nickname
                    state.isUserDataChanged.accept(isUserDataChanged)
                case .groupNameChanged(let groupName):
                    print("group name is changed: \(groupName)")
                    newGroupName = groupName
                    state.isUserDataChanged.accept(isUserDataChanged)
                case .profileImageChanged(let indexPath):
                    print("profile image is changed: \(indexPath)")
                    newProfileImageName = "profileImage\(indexPath.item + 1)"
                    state.isUserDataChanged.accept(isUserDataChanged)
                case .didTapEditButton:
                    print("did tap edit button.")
                    updateUserData()
                }
            }
            .disposed(by: disposeBag)
    }
    
    // 유저 데이터 업데이트
    private func updateUserData() {
        updateNickname()
        updateGroupName()
        updateProfileImage()
    }
    
    // 닉네임 업데이트
    private func updateNickname() {
        guard let newNickname, newNickname != state.user.value?.nickname else { return }
        
        guard let user = state.user.value else { return }
        let changedAt = Date()
        
        editProfileUseCaseImpl.updateUserNickname(userId: user.userID, groupId: user.groupID, nickname: newNickname, changedAt: changedAt)
            .subscribe {
                print("nickname update success: \(newNickname)")
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    // 그룹명 업데이트
    private func updateGroupName() {
        guard let newGroupName, newGroupName != state.user.value?.groupName else { return }
        
        guard let groupID = state.user.value?.groupID else { return }
        let changedAt = Date()
        
        editProfileUseCaseImpl.updateGroupName(groupId: groupID, name: newGroupName, changedAt: changedAt)
            .subscribe {
                print("group name update success: \(newGroupName)")
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    // 프로필 이미지 업데이트
    private func updateProfileImage() {
        guard let newProfileImageName, newProfileImageName != state.user.value?.profileImageURL else { return }
        
        guard let user = state.user.value else { return }
        
        editProfileUseCaseImpl.updateProfileImage(userId: user.userID, groupId: user.groupID, imageName: newProfileImageName)
            .subscribe {
                print("profile image update success: \(newProfileImageName)")
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
}
