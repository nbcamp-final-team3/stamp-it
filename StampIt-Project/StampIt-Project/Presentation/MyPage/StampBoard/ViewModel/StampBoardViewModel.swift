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
        case updateStamps([[StampBoardStamp]])
    }
    
    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let tabType = BehaviorRelay<TabType>(value: .stampBoard)
        let stampsByPage = BehaviorRelay<[[StampBoardStamp]]>(
            value: StampUtil.initialize()
        )
        let stampSummary = BehaviorRelay<(collected: Int, completed: Int)>(
            value: (.zero, .zero)
        )
    }
    
    // MARK: - Properties
    
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    
    private var lastCheckedAt: Date = .init()

    // MARK: - Initializer, Deinit, requiered
    
    init(myPageUseCase: MyPageUseCaseProtocol) {
        self.myPageUseCase = myPageUseCase
        bindAction()
    }
    
    // MARK: - Bind
    
    private func bindAction() {
        action.subscribe(with: self) { owner, action in
            switch action {
            case .viewDidLoad:
                owner.bindUser()
            case .tabButtonTapped(let type):
                owner.state.tabType.accept(type)
            case .updateStamps(let stamps):
                owner.state.stampsByPage.accept(stamps)
            }
        }.disposed(by: disposeBag)
    }
    
    private func bindUser() {
        myPageUseCase.fetchUser()
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, user in
                owner.state.user.accept(user)
                owner.bindStampSummaryData()
            }.disposed(by: disposeBag)
    }
    
    private func bindStampSummaryData() {
        guard let user = state.user.value else { return }
        
        /// stampSummary, stamps 가 동시에 변경
        myPageUseCase.observeStampCount(userId: user.userID)
            .flatMapLatest { [weak self] count -> Observable<(Int, [[StampBoardStamp]])> in
                guard let self else { return .empty() }
                
                let completedBoard = Int(count / Stamp.totalStamp)
                let currentPinNumber = completedBoard + 1

                if count == 0 { lastCheckedAt = .init() }
                
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
                let stampObservables = pinNumbers.map { pinNumber in
                    self.myPageUseCase.fetchStampsByPin(
                        userId: user.userID,
                        pinNumber: pinNumber
                    )
                }
                
                /// 순서에 맞게 페이지 별 스티커 배열 생성
                return Observable.combineLatest(stampObservables)
                    .map { [weak self] stampLists in
                        guard let self else { return (.init(), .init()) }
                        
                        var formattedStamps: [[StampBoardStamp]] = .init()
                        for (page, stamps) in stampLists.enumerated() {
                            /// 페이지에 맞게 스티커 색상 지정
                            formattedStamps.append(
                                stamps.enumerated().map { (index, stamp) in
                                    StampBoardStamp.map(
                                        stamp,
                                        type: StampType.from(page),
                                        lastCheckedAt: self.lastCheckedAt,
                                    )
                                }
                            )
                        }
                        return (count, formattedStamps)
                    }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self)  { owner, result in
                let (count, stamps) = result
                
                let totalStamp = Stamp.totalStamp
                let collectedStamp = Int(count % totalStamp)
                let completedBoard = Int(count / totalStamp)
                
                /// stampSummary 업데이트
                owner.state.stampSummary.accept((
                    collected: collectedStamp,
                    completed: completedBoard
                ))
                
                /// Zigzag 변환후 stamps 업데이트
                owner.updateStampZigzag(stamps)
            }.disposed(by: disposeBag)
    }
    
    private func updateStampZigzag(_ stampLists: [[StampBoardStamp]]) {
        let zigzagged: [[StampBoardStamp]] = stampLists
            .map { stamps in
                /// createdAt 오름차순 기준 정렬
                let ordered = stamps
                    .sorted { $0.createdAt < $1.createdAt }
                
                return StampUtil.makeZigzagOrder(
                    from: ordered,
                    columns: StampBoardSection.column,
                    pinNumber: state.stampSummary.value.completed
                )
            }
        state.stampsByPage.accept(zigzagged)
        disableBlurAfterDelay()
    }

    private func disableBlurAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }

            let updated = self.state.stampsByPage.value.map { section in
                section.map { stamp in
                    if stamp.shouldBlur {
                        var newStamp = stamp
                        newStamp.shouldBlur = false
                        return newStamp
                    }
                    return stamp
                }
            }

            self.state.stampsByPage.accept(updated)
        }
    }
}
