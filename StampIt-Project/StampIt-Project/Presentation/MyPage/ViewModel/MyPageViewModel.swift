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
        
        // TODO: 로그인 연결시 목데이터 삭제
        let stickers = BehaviorRelay<[Sticker]>(value: DummyData.stamps)
        let tabType = BehaviorRelay<TabType>(value: .stampBoard)
    }
    
    // MARK: - Properties
    
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    
    // TODO: 로그인 연결시 삭제
    // TODO: bindSticker() 내부에서 -> Sticker.maxStickers 변경
    // TODO: Sticker 필드 maxStickers 확인
    private let totalCount = 30
    
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
        guard let user = state.user.value else {
            // TODO: 로그인 연결시 목데이터 삭제
            self.state.stickers.accept(
                self.makeZigzagOrder(from: self.state.stickers.value, columns: MyPage.StampBoard.column)
            )
            return
        }
        myPageUseCase.fetchStickers(userId: user.userID)
            .subscribe(with: self) { owner, stickers in
                self.state.stickers.accept(
                    self.makeZigzagOrder(from: stickers, columns: MyPage.StampBoard.column)
                )
            }.disposed(by: disposeBag)
    }
    
    private func makeZigzagOrder(from stickers: [Sticker], columns: Int) -> [Sticker] {
        let totalStickers: [Sticker] = (0..<self.totalCount).map { index in
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

// TODO: 로그인 연결시 목데이터 삭제
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
        Sticker(stickerID: "10", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "11", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "12", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "13", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "14", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "15", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "16", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
        Sticker(stickerID: "17", title: "", description: "", imageURL: "", type: .stampRed, createdAt: Date()),
    ]
}
