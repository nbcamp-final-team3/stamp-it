//
//  HomeViewModel.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation
import RxSwift
import RxRelay

final class HomeViewModel: ViewModelProtocol {
    // MARK: - Dependency
    private let useCase: HomeUseCase

    // MARK: - Action & State
    enum Action {
        case viewDidLoad
        case viewWillAppear
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let rankedMembers = PublishRelay<[HomeItem]>()
    }

    // MARK: - Properties
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()

    // MARK: - Init
    init(useCase: HomeUseCase) {
        self.useCase = useCase
        bind()
    }

    // MARK: - Bind
    private func bind() {
        bindUser()
        bindRankedMembers()
    private func bindUser() {
        action
            .filter { $0 == .viewDidLoad }
            .flatMap { _ in self.useCase.fetchUser() }
            .bind(to: state.user)
            .disposed(by: disposeBag)
    }

    private func bindRankedMembers() {
        action
            .filter { $0 == .viewWillAppear }
            .flatMap { [weak self] _ -> Observable<[HomeItem]> in
                guard let self, let user = self.state.user.value else { return .empty() }
                return self.useCase.fetchRanking(ofGroup: "")
                    .map { self.mapUsersToHomeItems($0) }
            }
            .bind(to: state.rankedMembers)
            .disposed(by: disposeBag)
    }
    // MARK: - Methods
    private func mapUsersToHomeItems(_ users: [User]) -> [HomeItem] {
        users.map { user in
            let stickerCount = getStickerCount(ofUser: user)
            let member = HomeItem.HomeMember(
                nickname: user.nickname,
                stickerCount: stickerCount,
                profileImageURL: user.profileImageURL
            )
            return HomeItem.member(member)
        }
    }

    private func getStickerCount(ofUser user: User) -> Int {
        user.boards.reduce(0) { total, board in
            total + board.stickers.count
        }
    }
}
