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
        case tabButtonTapped(TabType)
    }
    
    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let stickers = BehaviorRelay<[Sticker]>(value: [])
        let tabType = BehaviorRelay<TabType>(value: .stampBoard)
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
                case .tabButtonTapped(let type):
                    owner.state.tabType.accept(type)
                }
            }.disposed(by: disposeBag)
    }
    
    private func bindUser() {
        myPageUseCase.fetchUser()
            .subscribe(with: self) { owner, user in
                self.state.user.accept(user)
                owner.bindSticker()
            }.disposed(by: disposeBag)
    }
    
    private func bindSticker() {
        // TODO: Sticker 엔티티 수정완료시 변경
//        guard let user = state.user.value else {
//            self.state.stickers.accept(
//                makeZigzagOrder(
//                    from: self.state.stickers.value,
//                    columns: MyPage.StampBoard.column
//                )
//            )
//            return
//        }
        myPageUseCase.fetchStickers(userId: "testUser001")
//        myPageUseCase.fetchStickers(userId: user.userID)
            .subscribe(
                with: self,
                onNext: { owner, stickers in
                    print("STICKER: \n\(stickers)")
                    self.state.stickers.accept(
                        self.makeZigzagOrder(from: stickers, columns: MyPage.StampBoard.column)
                    )
                }, onError: { owner, error in
                    print("BIND ERROR: \(error.localizedDescription)")
                }
            ).disposed(by: disposeBag)
    }
    
    private func makeZigzagOrder(from stickers: [Sticker], columns: Int) -> [Sticker] {
        let totalStickers: [Sticker] = (0..<MyPage.StampBoard.totalStampNumber).map { index in
            if index < stickers.count {
                return stickers[index]
            } else {
                return Sticker(stickerID: "\(UUID())", title: "", description: "", imageURL: "", type: .stampGray, createdAt: Date())
            }
        }
        
        let rows = stride(from: 0, to: totalStickers.count, by: columns)
            .map {
                Array(totalStickers[$0..<min($0 + columns, totalStickers.count)])
            }
        
        let ordered = rows.enumerated().flatMap { (index, row) in
            index.isMultiple(of: 2) ? row : row.reversed()
        }
        return ordered
    }
}
