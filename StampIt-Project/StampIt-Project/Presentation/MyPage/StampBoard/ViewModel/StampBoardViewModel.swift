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
        let stickersByPage = BehaviorRelay<[[StickerUI]]>(
            value: StickerUtil.initialize()
        )
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
        myPageUseCase.observeStickerCount(userId: user.userID)
            .flatMapLatest { [weak self] count -> Observable<(Int, [[StickerUI]])> in
                guard let self else { return .empty() }
                
                let completedBoard = Int(count / StampBoardSection.totalStamp)
                let currentPinNumber = completedBoard + 1
                
                let minPage = currentPinNumber > StampBoard.totalPage ? currentPinNumber - StampBoard.totalPage + 1 : 1
                
                var pinNumbers: [Int] = .init()
                
                /// pinNumber 기준 : Firestore pinNumber
                for pinNumber in stride(
                    from: currentPinNumber,
                    through: minPage,
                    by: -1
                ) {
                    pinNumbers.append(pinNumber)
                }
                
                /// pinNumber 로 페이지 별 모든 스티커 읽기
                let stickerObservables = pinNumbers.map { pinNumber in
                    self.myPageUseCase.fetchStickersByPin(
                        userId: user.userID,
                        pinNumber: pinNumber
                    )
                }
                
                /// 순서에 맞게 페이지 별 스티커 배열 생성
                return Observable.combineLatest(stickerObservables)
                    .map { stickerLists in
                        var formattedStickers: [[StickerUI]] = .init()
                        for (page, stickers) in stickerLists.enumerated() {
                            formattedStickers.append(
                                stickers.enumerated().map { (index, sticker) in
                                    StickerUI.map(sticker, type: StickerType.from(page))
                                }
                            )
                        }
                        return (count, formattedStickers)
                    }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self)  { owner, result in
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
    
    private func updateStickerZigzag(_ stickerLists: [[StickerUI]]) {
        let zigzagged: [[StickerUI]] = stickerLists
            .map { stickers in
                /// createdAt 내림차순 기준 정렬
                let ordered = stickers
                    .sorted { $0.createdAt > $1.createdAt }
                
                return StickerUtil.makeZigzagOrder(
                    from: ordered,
                    columns: StampBoardSection.column,
                    pinNumber: state.stickerSummary.value.completed
                )
            }
        
        state.stickersByPage.accept(zigzagged)
    }
}
