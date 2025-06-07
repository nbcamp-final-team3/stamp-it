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
        case didTapGroupOrganizationButton
        case didReceiveInvitationType(InvitationType)
        case didTapMissonCompleteButton(String)
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let isShowGroupOrganizationView = PublishRelay<Bool>()
        let rankedMembers = PublishRelay<[HomeItem]>()
        let receivedMissions = BehaviorRelay<[HomeItem]>(value: [])
        let sendedMissions = PublishRelay<[HomeItem]>()
        let isShowSelectInvitationVC = PublishRelay<Void>()
        let isPushSendInvitationVC = PublishRelay<Void>()
        let isPushReceiveInvitationVC = PublishRelay<Void>()
        let isShowStickerRecieved = PublishRelay<Void>()
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
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .viewDidLoad:
                    owner.bindUser()
                case .viewWillAppear:
                    owner.bindRankedMembers()
                    owner.bindReceivedMissions()
                    owner.bindSendedMissions()
                case .didTapGroupOrganizationButton:
                    owner.handleSelectIvitation()
                case .didReceiveInvitationType(let type):
                    owner.handleInvitation(type: type)
                case .didTapMissonCompleteButton(let id):
                    owner.handleMissionComplete(missionID: id)
                }
            }
            .disposed(by: disposeBag)
    }

    private func bindUser() {
        useCase.fetchUser()
            .bind(to: state.user)
            .disposed(by: disposeBag)
    }

    private func bindRankedMembers() {
        guard let user = state.user.value else { return }
        useCase.fetchRanking(ofGroup: user.groupID)
            .do(onNext: { [weak self] users in
                self?.memberCache = .init(uniqueKeysWithValues: users.map { ($0.userID, $0) })
            })
            .map { self.mapUsersToHomeItems($0) }
            .do(onNext: { [weak self] items in
                let isShow = items.count == 1
                self?.state.isShowGroupOrganizationView.accept(isShow)
            })
            .bind(to: state.rankedMembers)
            .disposed(by: disposeBag)
    }

    private func bindReceivedMissions() {
        guard let user = state.user.value else { return }
        useCase.fetchRecievedMissions(ofUser: user.userID)
            .map { self.mapReceivedMissionsToHomeItems($0) }
            .bind(to: state.receivedMissions)
            .disposed(by: disposeBag)
    }

    private func bindSendedMissions() {
        guard let user = state.user.value else { return }
        useCase.fetchSendedMissions(ofUser: user.userID)
            .map { self.mapSendedMissionsToHomeItems($0) }
            .bind(to: state.sendedMissions)
            .disposed(by: disposeBag)
    }

    private func handleSelectIvitation() {
        state.isShowSelectInvitationVC.accept(())
    }

    private func handleInvitation(type: InvitationType) {
        switch type {
        case .send:
            state.isPushSendInvitationVC.accept(())
        case .receive:
            state.isPushReceiveInvitationVC.accept(())
        }
    }

    private func handleMissionComplete(missionID: String) {
        useCase.updateMissionStatus(for: missionID, to: .completed)

        var missions = state.receivedMissions.value
        missions.removeAll(where: { $0.received!.missionID == missionID })
        state.receivedMissions.accept(missions)
    }

    // MARK: - Methods
    private func mapUsersToHomeItems(_ users: [User]) -> [HomeItem] {
        users.map { user in
            let stickerCount = getStickerCount(ofUser: user)
            let member = HomeItem.HomeMember(
                memberID: user.userID,
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
            let homeMission = HomeItem.HomeReceivedMission(
                missionID: mission.missionID,
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
                missionID: mission.missionID,
                title: mission.title,
                dueDate: mission.dueDate.toMonthDayString(),
                assigneeImageURL: assigneeImageURL,
                status: mission.status.text
            )
            return HomeItem.sended(homeMission)
        }
    }
}
