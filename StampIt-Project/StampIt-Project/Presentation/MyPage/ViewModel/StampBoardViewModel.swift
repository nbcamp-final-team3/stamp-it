//
//  StampBoardViewModel.swift
//  StampIt-Project
//
//  Created by kingj on 6/24/25.
//

import Foundation
import RxSwift
import RxRelay

final class StampBoardViewModel: ViewModelProtocol {
    
    // MARK: - Dependency
    
    private let myPageUseCase: MyPageUseCaseProtocol
    
    // MARK: - Action & State
    
    enum Action {
        case viewDidLoad
        case tabButtonTapped(TabType)
    }
    
    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let stickers = BehaviorRelay<[Sticker]>(value: [])
        let tabType = BehaviorRelay<TabType>(value: .stampBoard)
        let stickerSummary = BehaviorRelay<(collected: Int, completed: Int)>(value: (.zero, .zero))
    }
    
    // MARK: - Properties
    
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    
    // MARK: - Initializer, Deinit, requiered
    
    init(myPageUseCase: MyPageUseCaseProtocol) {
        self.myPageUseCase = myPageUseCase
        bindAction()
    }
    
    // MARK: - Bind
    
    private func bindAction() {
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
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, user in
                owner.state.user.accept(user)
                owner.bindStickerSummaryData()
            }.disposed(by: disposeBag)
    }
    
    private func bindStickerSummaryData() {
        guard let user = state.user.value else { return }
        
        /// stickerSummary, stickers 가 동시에 변경
        myPageUseCase.fetchStickerCount(userId: user.userID)
            .flatMapLatest { [weak self] count -> Observable<(Int, [Sticker])> in
                guard let self else { return .empty() }
                
                let completedBoard = Int(count / StampBoardSection.defaultBoard.totalStamp)
                let pinNumber = completedBoard + 1
                
                return self.myPageUseCase.fetchStickersByPin(
                    userId: user.userID,
                    pinNumber: pinNumber
                ).map { stickers in
                    return (count, stickers)
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, result in
                let (count, stickers) = result
                
                let totalSticker = StampBoardSection.defaultBoard.totalStamp
                let collectedSticker = Int(count % totalSticker)
                let completedBoard = Int(count / totalSticker)
                
                /// stickerSummary 업데이트
                owner.state.stickerSummary.accept((
                    collected: collectedSticker,
                    completed: completedBoard
                ))
                
                /// Zigzag 변환후 stickers 업데이트
                owner.updateStickerZigzag(stickers)
            }.disposed(by: disposeBag)
    }
    
    private func updateStickerZigzag(_ stickers: [Sticker]) {
        let zigzagged = makeZigzagOrder(
            from: stickers,
            columns: StampBoardSection.defaultBoard.column
        )
        state.stickers.accept(zigzagged)
    }
    
    private func makeZigzagOrder(from stickers: [Sticker], columns: Int) -> [Sticker] {
        let totalStickerCount = StampBoardSection.defaultBoard.totalStamp
        let totalStickers: [Sticker] = {
            (0..<totalStickerCount).map { index in
                if stickers.count == .zero {
                    return Sticker(userID: "", stickerID: "\(UUID())", title: "", description: "", imageURL: "", type: .stampGray, createdAt: Date(), maxStickers: 30, pinNumber: 1, assignedBy: "")
                } else {
                    if index < stickers.count {
                        return stickers[index]
                    } else {
                        return Sticker(userID: "", stickerID: "\(UUID())", title: "", description: "", imageURL: "", type: .stampGray, createdAt: Date(), maxStickers: 30, pinNumber: 1, assignedBy: "")
                    }
                }
            }
        }()
        
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
