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
        let isShowGroupOrganizationView = PublishRelay<Bool>()
        let rankedMembers = PublishRelay<[HomeItem]>()
        let receivedMissions = BehaviorRelay<[HomeItem]>(value: [])
        let sendedMissions = PublishRelay<[HomeItem]>()
    }

    // MARK: - Properties
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    var memberCache = [String: User]() // 멤버 정보 저장

    // MARK: - Init
    init(useCase: HomeUseCase) {
        self.useCase = useCase
        bind()
    }

    // MARK: - Bind
    private func bind() {
        bindUser()
        bindRankedMembers()
        bindReceivedMissions()
        bindSendedMissions()
    }

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
                    .do(onNext: { [weak self] users in
                        self?.memberCache = .init(uniqueKeysWithValues: users.map { ($0.userID, $0) })
                    })
                    .map { self.mapUsersToHomeItems($0) }
            }
            .do(onNext: { [weak self] items in
                let isShow = items.count == 1
                self?.state.isShowGroupOrganizationView.accept(isShow)
            })
            .bind(to: state.rankedMembers)
            .disposed(by: disposeBag)
    }

    private func bindReceivedMissions() {
        action
            .filter { $0 == .viewWillAppear }
            .flatMap { [weak self] _ -> Observable<[HomeItem]> in
                guard let self, let user = self.state.user.value else { return .empty() }
                return self.useCase.fetchRecievedMissions(ofUser: user.userID)
                    .map { self.mapReceivedMissionsToHomeItems($0) }
            }
            .bind(to: state.receivedMissions)
            .disposed(by: disposeBag)
    }

    private func bindSendedMissions() {
        action
            .filter { $0 == .viewWillAppear }
            .flatMap { [weak self] _ -> Observable<[HomeItem]> in
                guard let self, let user = self.state.user.value else { return .empty() }
                return self.useCase.fetchRecievedMissions(ofUser: user.userID)
                    .map { self.mapSendedMissionsToHomeItems($0) }
            }
            .bind(to: state.sendedMissions)
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

    private func mapReceivedMissionsToHomeItems(_ missions: [Mission]) -> [HomeItem] {
        missions.map { mission in
            let dueDateString = mission.dueDate.formatted()
            let homeMission = HomeItem.HomeReceivedMission(
                title: mission.title,
                dueDate: mission.dueDate.toMonthDayString(),
                assigner: mission.asignedBy,
                imageURL: mission.imageURL
            )
            return HomeItem.received(homeMission)
        }
    }

    private func mapSendedMissionsToHomeItems(_ missions: [Mission]) -> [HomeItem] {
        missions.map { mission in
            let assigneeImageURL = memberCache[mission.asignedTo]?.profileImageURL
            let homeMission = HomeItem.HomeSendedMission(
                title: mission.title,
                dueDate: mission.dueDate.toMonthDayString(),
                assigneeImageURL: assigneeImageURL,
                status: mission.status.text
            )
            return HomeItem.sended(homeMission)
        }
    }
}
