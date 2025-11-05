//
//  StampBoardViewModel.swift
//  StampIt-Project
//
//  Created by kingj on 6/24/25.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

final class StampBoardViewModel: ViewModelProtocol {
    
    // MARK: - Dependency
    
    private let myPageUseCase: MyPageUseCaseProtocol
    
    // MARK: - Action & State

    enum Action {
        case viewDidLoad
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let stampsByPage = BehaviorRelay<[[StampBoardStamp]]>(
            value: StampUtil.initialize()
        )
        let stampSummary = BehaviorRelay<(collected: Int, completed: Int)>(
            value: (.zero, .zero)
        )
    }

    // MARK: - Input & Output

    struct Input {
        let viewDidLoad: Signal<Void>
    }

    struct Output {
        let viewState: Driver<StampBoardViewState>
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

    // MARK: - Input Output

    func transform(from input: Input) -> Output {
        input.viewDidLoad
            .map { Action.viewDidLoad }
            .emit(to: action)
            .disposed(by: disposeBag)

        let user: Driver<User> = state.user
            .compactMap { $0 }
            .take(1)
            .asDriver(onErrorDriveWith: .empty())

        let stampCount: Driver<Int> = user
            .flatMap { [unowned self] user in
                observeStampCount(userID: user.userID)
                    .asDriver(onErrorDriveWith: .empty())
            }
            .distinctUntilChanged()

        let viewState: Driver<StampBoardViewState> = user
            .map { $0.userID }
            .flatMapLatest { [unowned self] id in
                makeViewStateDriver(id, stampCount.asObservable())
            }
            .asDriver(onErrorDriveWith: .empty())

        return Output(viewState: viewState)
    }

    // MARK: - Bind

    private func bindAction() {
        action.subscribe(with: self) { owner, action in
            switch action {
            case .viewDidLoad:
                owner.bindUser()
            }
        }.disposed(by: disposeBag)
    }
    
    private func bindUser() {
        myPageUseCase.fetchUser()
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, user in
                owner.state.user.accept(user)
            }.disposed(by: disposeBag)
    }

    /// View State 합쳐서 내보내기
    private func makeViewStateDriver(
        _ userID: String,
        _ stampCount: Observable<Int>
    ) -> Driver<StampBoardViewState> {
        let summary = observeStampSummary(stampCount)
        let pages = observeStampBoardPage(stampCount)
        let stamp = observeStamps(by: pages, userID)

        return Observable.combineLatest(summary, stamp, pages)
            .map { summary, stamp, pages in
                let numberOfPages = pages.count
                return StampBoardViewState(
                    collectdStamp: summary.collected,
                    completedBoard: summary.completed,
                    stampsByPage: stamp,
                    numberOfPages: numberOfPages
                )
            }
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
    }

    /// 총 스탬프 개수 가져오기
    private func observeStampCount(userID: String) -> Observable<Int> {
        myPageUseCase.observeStampCount(userId: userID)
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)
    }

    /// 현재 스탬프 개수, 총 스탬프 보드 수 계산
    private func observeStampSummary(
        _ stampCount: Observable<Int>
    ) -> Observable<(collected: Int, completed: Int)> {
        let summary = stampCount.map { count -> (collected: Int, completed: Int) in
            let total = Stamp.totalStamp
            return (count % total, count / total)
        }
            .distinctUntilChanged {
                ($0.collected == $1.collected) && ($0.completed == $1.completed)
            }
            .share(replay: 1, scope: .whileConnected)
        return summary
    }

    /// 총 스탬프보드 수 계산
    private func observeStampBoardPage(
        _ stampCount: Observable<Int>
    ) -> Observable<[Int]> {
        let pages = stampCount.map { count -> [Int] in
            let completed = count / Stamp.totalStamp
            let currentPage = completed + 1
            let lastPage = max(1, currentPage - StampBoard.totalPage + 1)
            return Array(stride(from: currentPage, through: lastPage, by: -1))
        }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)
        return pages
    }

    /// 총 스탬프 가져오기
    private func observeStamps(
        by pages: Observable<[Int]>,
        _ userID: String
    ) -> Observable<[[StampBoardStamp]]> {
        let stampsByPage = pages
            .flatMapLatest { [weak self] pages -> Observable<[[StampBoardStamp]]> in
                guard let self else { return .empty() }
                let stampObservables: [Observable<[StampBoardStamp]>] = pages
                    .map { [weak self] page -> Observable<[StampBoardStamp]> in
                        guard let self else { return .empty() }
                        return myPageUseCase.fetchStampsByPage(userId: userID, page: page)
                    }
                return Observable.combineLatest(stampObservables)
            }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)
        return stampsByPage
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
                    self.myPageUseCase.fetchStampsByPage(
                        userId: user.userID,
                        page: pinNumber
                    )
                }
                
                /// 순서에 맞게 페이지 별 스티커 배열 생성
                return Observable.combineLatest(stampObservables)
                    .map { [weak self] stampLists in
                        guard let self else { return (.init(), .init()) }
                        
                        var stampsByPage: [[StampBoardStamp]] = .init()
                        for (page, stamps) in stampLists.enumerated() {
                            /// 페이지에 맞게 스티커 색상 지정
                            stampsByPage.append(
                                stamps.enumerated().map { (index, stamp) in
                                    StampBoardStamp.map(
                                        stamp,
                                        type: StampType.from(page),
                                        lastCheckedAt: self.lastCheckedAt,
                                    )
                                }
                            )
                        }
                        return (count, stampsByPage)
                    }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(with: self)  { owner, result in
                /// count: 총 스탬프 개수, stampsByPage: 페이지 별 스탬프 개수
                let (count, stampsByPage) = result
                
                let totalStamp = Stamp.totalStamp
                let collectedStamp = Int(count % totalStamp)
                let completedBoard = Int(count / totalStamp)
                
                /// stampSummary 업데이트
                owner.state.stampSummary.accept((
                    collected: collectedStamp,
                    completed: completedBoard
                ))
                
                /// Zigzag 변환후 stamps 업데이트
                owner.updateStampZigzag(stampsByPage)
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
