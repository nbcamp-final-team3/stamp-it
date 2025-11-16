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
        let currentRealIdRelay = BehaviorRelay<Set<StampCellIdentity>>(value: .init())
        let appearanceCache = BehaviorRelay<[StampCellIdentity: StampCellAppearance]>(value: .init())
    }

    // MARK: - Input & Output

    struct Input {
        let viewDidLoad: Signal<Void>
    }

    struct Output {
        let viewState: Driver<StampBoardViewState>
        let reconfigureID: Driver<[StampCellIdentity]>
        let appearanceCache: Driver<[StampCellIdentity: StampCellAppearance]>
    }

    // MARK: - Properties
    
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()

    private var isInitialBoardLoaded: Bool = false

    // MARK: - Initializer, Deinit, requiered
    
    init(myPageUseCase: MyPageUseCaseProtocol) {
        self.myPageUseCase = myPageUseCase
        bindAction()
    }

    // MARK: - External Interface

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

        let reconfigureOn = startHighlightAnimation()
            .share(replay: 1, scope: .whileConnected)

        let reconfigureOff = endHighlightAnimation(reconfigureOn)
            .share(replay: 1, scope: .whileConnected)

        let reconfigureID: Driver<[StampCellIdentity]> = Observable
            .merge(reconfigureOn, reconfigureOff)
            .map { Array(Set($0)) }
            .asDriver(onErrorDriveWith: .empty())

        let appearanceCache = state.appearanceCache.asDriver(onErrorDriveWith: .empty())

        return Output(
            viewState: viewState,
            reconfigureID: reconfigureID,
            appearanceCache: appearanceCache
        )
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

    // MARK: - ViewState Stream Builder

    private func makeViewStateDriver(
        _ userID: String,
        _ stampCount: Observable<Int>
    ) -> Driver<StampBoardViewState> {
        let summary = observeStampSummary(stampCount)
        let stamps = observeStamps(by: stampCount, userID)

        stamps
            .map { [weak self] stamps -> [StampCellIdentity: StampCellAppearance] in
                guard let self else { return .init() }
                return StampUtil.makeBoardAppearance(
                    with: stamps,
                    cache: state.appearanceCache.value,
                    isInitialBoardLoaded: isInitialBoardLoaded
                )
            }
            .subscribe(with: self) { owner, appearance in
                owner.state.appearanceCache.accept(appearance)
            }
            .disposed(by: disposeBag)

        stamps
            .map { StampUtil.makeRealID(with: $0) }
            .subscribe(with: self) { owner, currentRealID in
                owner.state.currentRealIdRelay.accept(currentRealID)
            }
            .disposed(by: disposeBag)

        return Observable.combineLatest(
            summary,
            stamps,
            state.appearanceCache.asObservable()
        )
        .map { summary, stamps, appearance in
            StampBoardViewState(
                collectdStamp: summary.collected,
                completedBoard: summary.completed,
                stampContent: StampUtil.makeBoardContent(with: stamps),
                stampAppearance: appearance,
                stampIdentityByPage: StampUtil.makeBoardIdentity(stamps.count)
            )
        }
        .distinctUntilChanged()
        .asDriver(onErrorDriveWith: .empty())
        .startWith(StampUtil.makeDefaultViewState())
    }

    private func observeStampCount(userID: String) -> Observable<Int> {
        myPageUseCase.observeStampCount(userId: userID)
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)
    }

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

    private func observeStamps(
        by stampCount: Observable<Int>,
        _ userID: String
    ) -> Observable<[[StampBoardStamp]]> {
        stampCount
            .distinctUntilChanged()
            .debounce(.milliseconds(120), scheduler: MainScheduler.instance)
            .map { count -> [Int] in
                let completed = count / Stamp.totalStamp
                let currentPage = completed + 1
                let lastPage = max(1, currentPage - StampBoard.totalPage + 1)
                return Array(stride(from: lastPage, through: currentPage, by: 1))
            }
            .flatMapLatest { [weak self] pages -> Observable<[[StampBoardStamp]]> in
                guard let self else { return .empty() }
                let stampObservables: [Observable<[StampBoardStamp]>] = pages
                    .map { self.myPageUseCase.fetchStampsByPage(userId: userID, page: $0) }
                return Observable.combineLatest(stampObservables)
            }
    }

    private func startHighlightAnimation() -> Observable<[StampCellIdentity]> {
            state.currentRealIdRelay
                .skip(1)
                .scan(
                    (prevIDs: Set<StampCellIdentity>(), addedIDs: [StampCellIdentity]())
                ) { accumulator, currentIDs in
                    let addedIDs = Array(currentIDs.subtracting(accumulator.prevIDs))
                    return (prevIDs: currentIDs, addedIDs: addedIDs)
                }
                .map { $0.addedIDs }
                .map { [weak self] addedIDs -> [StampCellIdentity] in
                    guard let self else { return .init() }

                    /// 초기 1회 스킵 : 하이라이팅 애니메이션 실행 안함
                    if !isInitialBoardLoaded {
                        isInitialBoardLoaded = true
                        return []
                    }
                    return addedIDs
                }
        }

    private func endHighlightAnimation(
        _ reconfigureIDs: Observable<[StampCellIdentity]>
    ) -> Observable<[StampCellIdentity]> {
        reconfigureIDs
            .flatMap { addedIDs -> Observable<[StampCellIdentity]> in
                /// [ID] -> ID 하나씩
                Observable.from(addedIDs)
                    .flatMap { id -> Observable<[StampCellIdentity]> in
                        /// 각 ID 마다 개별 3초 타이머
                        Observable.just(id)
                            .delay(.seconds(3), scheduler: MainScheduler.instance)
                            .do { [weak self] id in
                                guard let self else { return }
                                var cache = state.appearanceCache.value
                                if var newAppearance = cache[id] {
                                    newAppearance.isHighlighted = true
                                    cache[id] = newAppearance
                                    state.appearanceCache.accept(cache)
                                }
                            }
                            .map { [$0] }
                    }
            }
    }
}
