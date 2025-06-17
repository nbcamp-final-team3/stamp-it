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

    private let useCase: HomeUseCaseProtocol

    // MARK: - Action & State

    enum Action {
        case viewWillAppear
        case didTapGroupOrganizationButton
        case didReceiveInvitationType(InvitationType)
        case didTapMissonCompleteButton(String)
        case didTapCompleteCancelButton
        case didTapMoreReceivedMissions
        case didSelectReceivedMember(memberID: String)
        case didTapMoreSendedMissions
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
        let isShowStickerReceived = PublishRelay<Void>()
        let isPushMyMissionVC = PublishRelay<Void>()
        let isPushMemberMissionVC = PublishRelay<Void>()
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    var memberCache = [String: Member]() // 멤버 정보 저장
    private var receivedMissions = [Mission]() // Firestore 상태 업데이트용 도메인 미션 캐시
    private var sendedMissions = [Mission]()
    private var pendingCommits = DisposeBag()

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
                case .viewWillAppear:
                    owner.showPlaceholderOnSendedSection()
                    owner.bindUser()
                case .didTapGroupOrganizationButton:
                    owner.handleSelectIvitation()
                case .didReceiveInvitationType(let type):
                    owner.handleInvitation(type: type)
                case .didTapMissonCompleteButton(let id):
                    owner.handleMissionCompleteButtonTapped(missionID: id)
                case .didTapCompleteCancelButton:
                    owner.cancelMissionComplete()
                case .didTapMoreReceivedMissions:
                    owner.state.isPushMyMissionVC.accept(())
                case .didSelectReceivedMember(memberID: let id):
                    owner.updateSendedMissions(memberID: id)
                case .didTapMoreSendedMissions:
                    owner.state.isPushMemberMissionVC.accept(())
                }
            }
            .disposed(by: disposeBag)
    }

    /// user 정보 바인딩
    private func bindUser() {
        useCase.fetchCurrentUser()
            .compactMap { $0 }
            .flatMap { [weak self] user -> Observable<([Member], [Mission], [Mission])> in
                guard let self else { return .empty() }
                state.user.accept(user)
                let rankingObs = useCase.fetchRanking(ofGroup: user.groupID)
                    .do(onNext: { members in
                        self.memberCache = Dictionary(uniqueKeysWithValues: members.map { ($0.userID, $0) })
                    })
                let receivedObs = useCase.fetchReceivedMissions(ofUser: user.userID, fromGroup: user.groupID)
                    .do(onNext: { receivedMissions in
                        self.receivedMissions = receivedMissions
                    })
                let sendedObs = useCase.fetchSendedMissions(ofUser: user.userID, fromGroup: user.groupID)
                    .do(onNext: { sendedMissions in
                        self.sendedMissions = sendedMissions
                    })

                return Observable.zip(rankingObs, receivedObs, sendedObs)
            }
            .subscribe(onNext: { [weak self] (member: [Member], received: [Mission], sended: [Mission]) in
                guard let self else { return }

                let memberItems = mapMembersToHomeItems(member)
                #if !DEBUG
                state.isShowGroupOrganizationView.accept(users.count == 1)
                #endif
                state.rankedMembers.accept(memberItems)

                let receivedItems = mapReceivedMissionsToHomeItems(received)
                state.receivedMissions.accept(receivedItems)

                let sendedMissionsForDisplay = mapSendedMissionsToHomeItems(Array(sended.prefix(4)))
                state.sendedMissionsForDisplay.accept(sendedMissionsForDisplay)
            })
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
    func handleMissionCompleteButtonTapped(missionID: String) {
        removeMissionItem(missionID: missionID)

        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.cancelMissionComplete()
        }
        #endif

        // cancelMissionComplete() 호출 시 dispose되는 Observable
        Observable<Void>.just(())
            .delay(.seconds(4), scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self else { return .empty() }
                let removedMission = removeMissionCache(missionID: missionID)

                guard let mission = removedMission,
                      let user = state.user.value else { return .empty() }

                return useCase.updateMissionStatus(for: mission, ofGroup: user.groupID, to: .completed)
            }
            .subscribe()
            .disposed(by: pendingCommits)
    }

    /// UI에서 미션 제거
    private func removeMissionItem(missionID: String) {
        let missions = state.receivedMissions.value
        let updated = missions.filter { $0.received!.missionID != missionID }
        state.receivedMissions.accept(updated)
    }

    /// 도메인 미션 캐시에서 미션 제거
    private func removeMissionCache(missionID: String) -> Mission? {
        guard let index = receivedMissions.firstIndex(where: { $0.missionID == missionID }) else { return nil }
        return receivedMissions.remove(at: index)
    }

    /// 토스트 “취소하기” 버튼 눌렀을 때 호출
    func cancelMissionComplete() {
        pendingCommits = DisposeBag()
        let cachedMissions = mapReceivedMissionsToHomeItems(receivedMissions)
        state.receivedMissions.accept(cachedMissions)
    }

    // MARK: - Methods

    /// fetch 전 placeholder 제공
    private func showPlaceholderOnSendedSection() {
        state.sendedMissionsForDisplay.accept([])
    }

    /// [User]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
    private func mapMembersToHomeItems(_ members: [Member]) -> [HomeItem] {
        members.enumerated().map { index, member in
            let member = HomeMember(
                memberID: member.userID,
                nickname: member.nickname,
                stickerCount: "\(member.monthSticker)개",
                rank: index + 1,
                profileImageURL: member.profileImageURL
            )
            return HomeItem.member(member)
        }
    }

    /// [Mission]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
    private func mapReceivedMissionsToHomeItems(_ missions: [Mission]) -> [HomeItem] {
        missions.map { mission in
            let assigner = memberCache[mission.assignedBy]?.nickname ?? mission.assignedBy
            let homeMission = HomeReceivedMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assigner: assigner,
                isNew: nil,
                isOverdue: formatOverdueAndDays(from: mission.dueDate).isOverdue,
                status: mission.status
            )
            return HomeItem.received(homeMission)
        }
    }

    /// [Mission]를 컬렉션뷰에서 사용하는 [HomeItem]으로 매핑
    private func mapSendedMissionsToHomeItems(_ missions: [Mission]) -> [HomeItem] {
        missions.map { mission in
            let assignee = memberCache[mission.assignedTo]?.nickname ?? ""
            let (isOverdue, daysLeft) = formatOverdueAndDays(from: mission.dueDate)
            let homeMission = HomeSendedMission(
                missionID: mission.missionID,
                title: mission.title,
                category: mission.category,
                dueDate: mission.dueDate.toMonthDayString(),
                assignee: assignee,
                status: mission.status,
                isOverdue: isOverdue,
                daysLeft: daysLeft,
            )
            return HomeItem.sended(homeMission)
        }
    }

    private func formatOverdueAndDays(from dueDate: Date) -> (isOverdue: Bool, daysLeft: String) {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        let dueStart = cal.startOfDay(for: dueDate)

        let dayDiff = cal.dateComponents([.day], from: todayStart, to: dueStart).day ?? 0

        let isOverdue = dayDiff < 0
        let daysLeft = dayDiff == 0 ? "오늘" : "\(dayDiff)일 전"

        return (isOverdue, daysLeft)
    }
}
