//
//  MyPageViewModel.swift
//  StampIt-Project
//
//  Created by kingj on 6/11/25.
//

import Foundation
import RxSwift
import RxRelay

final class MyPageViewModel: ViewModelProtocol {
    
    // MARK: - Dependency

    private let myPageUseCase: MyPageUseCase
    
    // MARK: - Action & State
    
    enum Action {
        case viewDidLoad
    }
    
    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let stickers = BehaviorRelay<[Sticker]>(value: DummyData.stamps)
    }
    
    // MARK: - Properties
    
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(myPageUseCase: MyPageUseCase) {
        self.myPageUseCase = myPageUseCase
        bind()
    }
    
    // MARK: - Bind
    
    private func bind() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .viewDidLoad:
                    owner.bindUser()
                    owner.bindSticker()
                }
            }.disposed(by: disposeBag)
    }
    
    private func bindUser() {
        myPageUseCase.fetchUser()
            .subscribe(with: self) { owner, user in
                self.state.user.accept(user)
            }.disposed(by: disposeBag)
    }
    
    private func bindSticker() {
        guard let user = state.user.value else { return }
        myPageUseCase.fetchStickers(userId: user.userID)
            .subscribe(with: self) { owner, stickers in
                self.state.stickers.accept(stickers)
            }.disposed(by: disposeBag)
    }
    
    // UI 확인용 데이터
}

struct DummyData {
    static let stamps: [Sticker] = [
        Sticker(stickerID: "1", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "2", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "3", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "4", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "5", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "6", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "7", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "8", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "9", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
    ]
}
