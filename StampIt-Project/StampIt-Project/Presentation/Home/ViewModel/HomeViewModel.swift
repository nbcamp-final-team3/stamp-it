//
//  HomeViewModel.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation
import RxSwift
import RxRelay
import UIKit

final class HomeViewModel: ViewModelProtocol {
    // MARK: - Dependency

    private let useCase: HomeUseCaseProtocol

    // MARK: - Action & State

    enum Action {
        case viewDidLoad
        case viewWillAppear
        case didTapGroupOrganizationButton
        case didReceiveInvitationType(InvitationType)
        case didTapMissonCompleteButton(String)
        case didTapMoreReceivedMissions
        case didSelectReceivedMember(memberID: String)
        case didTapMoreSenededMissions
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let isShowGroupOrganizationView = PublishRelay<Bool>()
        let rankedMembers = PublishRelay<[HomeItem]>()
        let receivedMissions = BehaviorRelay<[HomeItem]>(value: [])
        let sendedMissionsForDisplay = PublishRelay<[HomeItem]>()
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
    private var memberCache = [String: User]() // 멤버 정보 저장
    private var sendedMissions = [Mission]()

    // MARK: - Init

    init(useCase: HomeUseCaseProtocol) {
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
                case .didSelectReceivedMember(memberID: let id):
                    owner.updateSendedMissions(memberID: id)
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
            .do(onNext: { [weak self] sendedMissions in
                self?.sendedMissions = sendedMissions
            })
            .map { self.mapSendedMissionsToHomeItems(Array($0.prefix(4))) }
            .bind(to: state.sendedMissionsForDisplay)
            .disposed(by: disposeBag)
    }

    /// 멤버 ID가 nil이면 전체, 값이 있으면 해당 멤버에게 전달한 미션만 필터링하여 최근 전달한 4개를 accept
    private func updateSendedMissions(memberID: String?) {
        let filteredMissions = memberID
            .map { id in sendedMissions.filter { $0.assignedTo == memberID } }
            ?? sendedMissions
        let first4 = Array(filteredMissions.prefix(4))
        let homeItems = mapSendedMissionsToHomeItems(first4)
        state.sendedMissionsForDisplay.accept(homeItems)
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
        users.enumerated().map { index, user in
            let stickerCount = getStickerCount(ofUser: user)
            let member = HomeMember(
                memberID: user.userID,
                nickname: user.nickname,
                stickerCount: "\(stickerCount)개",
                rank: index + 1,
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
            let homeMission = HomeReceivedMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assigner: mission.assignedBy,
                // TODO: UseCase에서 isNew 판별
                isNew: true
            )
            return HomeItem.received(homeMission)
        }
    }

    /// [Mission]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
    private func mapSendedMissionsToHomeItems(_ missions: [Mission]) -> [HomeItem] {
        missions.map { mission in
            let assignee = memberCache[mission.assignedTo]?.nickname ?? ""
            let homeMission = HomeSendedMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assignee: assignee,
                status: mission.status,
                // TODO: 계산해서 할당
                isOverdue: true,
                daysLeft: "3일 전"
            )
            return HomeItem.sended(homeMission)
        }
    }
}
