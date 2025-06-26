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
        let stickersByPage = BehaviorRelay<[[Sticker]]>(value: .init())
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
            .flatMapLatest { [weak self] count -> Observable<(Int, [[Sticker]])> in
                guard let self else { return .empty() }
                
                let completedBoard = Int(count / StampBoardSection.totalStamp)
                let currentPinNumber = completedBoard + 1
                
                let minPage = currentPinNumber > StampBoard.totalPage ? currentPinNumber - StampBoard.totalPage : currentPinNumber
                
                var pinNumbers: [Int] = .init()
                
                for index in stride(from: currentPinNumber, through: minPage, by: -1) {
                    pinNumbers.append(index)
                }
                
                return Observable.from(pinNumbers)
                    .flatMap { pinNumber in // Observable<[Sticker]>
                        self.myPageUseCase.fetchStickersByPin(
                            userId: user.userID,
                            pinNumber: pinNumber
                        )
                    }
                    .toArray() // Single<[[Sticker]]> : [Sticker] -> [[Sticker]]
                    .map { (stickers: [[Sticker]]) in
                        return (count, stickers)
                    }
                    .asObservable()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, result in
                let (count, stickers) = result
                
                let totalSticker = StampBoardSection.totalStamp
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
    
    private func updateStickerZigzag(_ stickers: [[Sticker]]) {
        let zigzagged: [[Sticker]] = stickers.map {
            makeZigzagOrder(
                from: $0,
                columns: StampBoardSection.column
            )
        }
        state.stickersByPage.accept(zigzagged)
    }
    
    private func makeZigzagOrder(from stickers: [Sticker], columns: Int) -> [Sticker] {
        let totalStickerCount = StampBoardSection.totalStamp
        let totalStickers: [Sticker] = {
            (0..<totalStickerCount).map { index in
                
                /// Empty stickers 배열 일 때 default stamp 생성
                if stickers.count == .zero {
                    return makeEmptySticker()
                } else {
                    /// stickers 배열이 1 이상, totalStickerCount 이하 일 경우
                    if index < stickers.count {
                        return stickers[index]
                    } else {
                        return makeEmptySticker()
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
    
    private func makeEmptySticker() -> Sticker {
        
        // TODO: type 체크
        
        Sticker(
            userID: "",
            stickerID: "\(UUID())",
            title: "",
            description: "",
            imageURL: "",
            type: .stampGray,
            createdAt: Date(),
            maxStickers: 30,
            pinNumber: state.stickerSummary.value.completed,
            assignedBy: ""
        )
    }
}
