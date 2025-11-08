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

    // MARK: - ViewState Stream Builder

    private func makeViewStateDriver(
        _ userID: String,
        _ stampCount: Observable<Int>
    ) -> Driver<StampBoardViewState> {
        let summary = observeStampSummary(stampCount)
        let stamps = observeStamps(by: stampCount, userID)

        return Observable.combineLatest(summary, stamps)
            .map { summary, stamps in
                return StampBoardViewState(
                    collectdStamp: summary.collected,
                    completedBoard: summary.completed,
                    stampsByPage: stamps,
                    stampIdentity: StampUtil.makeStampBoardContent(with: stamps),
                    stampIdentityByPage: StampUtil.makeStampBoardIdentity(stamps.count)
                )
            }
            .distinctUntilChanged()
            .asDriver(onErrorDriveWith: .empty())
            .startWith(StampUtil.makeInitialViewState())
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
                return Array(stride(from: currentPage, through: lastPage, by: -1))
            }
            .flatMapLatest { [weak self] pages -> Observable<[[StampBoardStamp]]> in
                guard let self else { return .empty() }
                let stampObservables: [Observable<[StampBoardStamp]>] = pages
                    .map { self.myPageUseCase.fetchStampsByPage(userId: userID, page: $0) }
                return Observable.combineLatest(stampObservables)
            }
    }
}
