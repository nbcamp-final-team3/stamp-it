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
        case didTapMoreReceivedMissions
        case didTapMoreSenededMissions
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
        let isPushReceivedMissionVC = PublishRelay<Void>()
        let isPushSendedMissionVC = PublishRelay<Void>()
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
                case .didTapMoreReceivedMissions:
                    owner.state.isPushReceivedMissionVC.accept(())
                case .didTapMoreSenededMissions:
                    owner.state.isPushSendedMissionVC.accept(())
                }
            }
            .disposed(by: disposeBag)
    }

    /// user 정보 바인딩
    private func bindUser() {
        useCase.fetchUser()
            .bind(to: state.user)
            .disposed(by: disposeBag)
    }

    /// 유저가 속한 그룹의 멤버 랭킹 바인딩
    ///
    /// HomeItem으로 매핑하기 전에 멤버 정보 캐싱하고,
    /// 멤버가 1명(유저 혼자)이면 그룹 구성하기 뷰로 전환
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

    /// 유저가 그룹 구성원으로부터 받은 미션 바인딩
    private func bindReceivedMissions() {
        guard let user = state.user.value else { return }
        useCase.fetchRecievedMissions(ofUser: user.userID)
            .map { self.mapReceivedMissionsToHomeItems($0) }
            .bind(to: state.receivedMissions)
            .disposed(by: disposeBag)
    }

    /// 유저가 다른 그룹 구성원에게 보낸 미션 바인딩
    private func bindSendedMissions() {
        guard let user = state.user.value else { return }
        useCase.fetchSendedMissions(ofUser: user.userID)
            .map { self.mapSendedMissionsToHomeItems($0) }
            .bind(to: state.sendedMissions)
            .disposed(by: disposeBag)
    }

    /// 그룹 구성하기 버튼 탭 시 초대하기/초대받기 선택할 수 있는 뷰 제공
    private func handleSelectIvitation() {
        state.isShowSelectInvitationVC.accept(())
    }

    /// 초대하기/초대받기 선택에 따라 VC push
    private func handleInvitation(type: InvitationType) {
        switch type {
        case .send:
            state.isPushSendInvitationVC.accept(())
        case .receive:
            state.isPushReceiveInvitationVC.accept(())
        }
    }

    /// 미션 완료 바인딩
    ///
    /// 미션 완료 API를 호출하고,
    /// 전달받은 미션의 ID로 receivedMissions에서 해당 미션을 찾아 제거
    private func handleMissionComplete(missionID: String) {
        useCase.updateMissionStatus(for: missionID, to: .completed)

        var missions = state.receivedMissions.value
        missions.removeAll(where: { $0.received!.missionID == missionID })
        state.receivedMissions.accept(missions)
    }

    // MARK: - Methods

    /// [User]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
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

    /// User가 가진 모든 스티커 수의 합 반환
    private func getStickerCount(ofUser user: User) -> Int {
        user.boards.reduce(0) { total, board in
            total + board.stickers.count
        }
    }

    /// [Mission]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
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

    /// [Mission]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
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
