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
        case profileImageChanged(IndexPath) // indexPath 최선인가요?????????????????
        // case profileImageChanged(String)
        case didTapEditButton
    }
    
    struct State {
        var user = BehaviorRelay<User?>(value: nil)
        var isEditButtonEnabled = BehaviorRelay<Bool>(value: false)
    }
    
    var action = PublishRelay<Action>()
    var state = State()
    
    var disposeBag = DisposeBag()
    
    private let editProfileUseCaseImpl: EditProfileUseCase
    
    // private let _user: User
    private var newNickname: String?
    private var newGroupName: String?
    private var newProfileImageName: String?
    
//    private var isUserDataChanged: Bool {
//        newNickname == state.user.value?.nickname || newGroupName == state.user.value?.groupName || newProfileImageName == state.user.value?.profileImageURL
//    }
    
//    private var isUserDataChanged: Bool {
//        newNickname != state.user.value?.nickname ||
//        newGroupName != state.user.value?.groupName ||
//        newProfileImageName != state.user.value?.profileImageURL
//    }
    
//    private func isUserDataChanged() -> Bool {
//        newNickname != state.user.value?.nickname ||
//        newGroupName != state.user.value?.groupName ||
//        newProfileImageName != state.user.value?.profileImageURL
//    }
    
//    private var isUserDataChanged: Bool {
//        guard let user = state.user.value else { return false }
//        print("newNickname: \(newNickname), newGroupName: \(newGroupName), newProfileImageName: \(newProfileImageName)")
//        return newNickname != user.nickname ||
//               newGroupName != user.groupName ||
//               newProfileImageName != user.profileImageURL
//    }

    private var isUserDataChanged: Bool {
        guard let user = state.user.value else { return false }
        return (newNickname ?? user.nickname) != user.nickname ||
               (newGroupName ?? user.groupName) != user.groupName ||
               (newProfileImageName ?? user.profileImageURL) != user.profileImageURL
    }
    
    init(user: User, editProfileUseCaseImpl: EditProfileUseCase = EditProfileUseCaseImpl()) {
        // self._user = user
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
                    // state.user.accept(_user)
                case .nicknameChanged(let nickname):
                    print("nickname is changed: \(nickname)")
                    newNickname = nickname
                    
//                    if nickname != state.user.value?.nickname {
//                        newNickname = nickname
//                        state.isEditButtonEnabled.accept(true)
//                    } else {
//                        state.isEditButtonEnabled.accept(false)
//                    }
                    
                    if isUserDataChanged {
                        state.isEditButtonEnabled.accept(true)
                    } else {
                        state.isEditButtonEnabled.accept(false)
                    }
                    
                case .groupNameChanged(let groupName):
                    print("group name is changed: \(groupName)")
                    newGroupName = groupName
                    
//                    if groupName != state.user.value?.groupName {
//                        newGroupName = groupName
//                        state.isEditButtonEnabled.accept(true)
//                    } else {
//                        state.isEditButtonEnabled.accept(false)
//                    }
                    
                    if isUserDataChanged {
                        state.isEditButtonEnabled.accept(true)
                    } else {
                        state.isEditButtonEnabled.accept(false)
                    }
                case .profileImageChanged(let indexPath):
                    // print("profile image is changed: \(indexPath)")
                    newProfileImageName = "profileImage\(indexPath.item + 1)"
                    
                    if isUserDataChanged {
                        state.isEditButtonEnabled.accept(true)
                    } else {
                        state.isEditButtonEnabled.accept(false)
                    }
                    
                    
                    
                    print("profile image is changed: \(newProfileImageName)")
                    
                    
                    
                    
                    
                case .didTapEditButton:
                    print("did tap edit button.")
                    updateNickname()
                    updateGroupName()
                    updateProfileImage()
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func updateNickname() {
        guard let newNickname, newNickname != state.user.value?.nickname else { return }
        
        guard let userID = state.user.value?.userID else { return }
        print("nickname: \(newNickname)")
        let changedAt = Date()
        editProfileUseCaseImpl.updateUserNickname(userId: userID, nickname: newNickname, changedAt: changedAt)
            .subscribe {
                print("nickname update success: \(newNickname)")
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    private func updateGroupName() {
        guard let newGroupName, newGroupName != state.user.value?.groupName else { return }
        
        guard let groupID = state.user.value?.groupID else { return }
        print("group name: \(newGroupName)")
        let changedAt = Date()
        editProfileUseCaseImpl.updateGroupName(groupId: groupID, name: newGroupName, changedAt: changedAt)
            .subscribe {
                print("group name update success: \(newGroupName)")
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
    
    private func updateProfileImage() {
        guard let newProfileImageName, newProfileImageName != state.user.value?.profileImageURL else { return }
        
        guard let userID = state.user.value?.userID else { return }
        print("Imagename: \(newProfileImageName)")
        editProfileUseCaseImpl.updateProfileImage(userId: userID, imageName: newProfileImageName)
            .subscribe {
                print("image update success: \(newProfileImageName)")
            } onError: { error in
                print(error)
            }
            .disposed(by: disposeBag)
    }
}
