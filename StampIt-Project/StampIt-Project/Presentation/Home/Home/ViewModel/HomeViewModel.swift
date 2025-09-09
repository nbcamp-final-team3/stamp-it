//
//  HomeViewModel.swift
//  StampIt-Project
//
//  Created by 곽다은 on 6/6/25.
//

import Foundation
import RxSwift
import RxRelay
import WidgetKit

final class HomeViewModel: ViewModelProtocol {
    // MARK: - Dependency

    private let rankingUseCase: RankingUseCaseProtocol
    private let myMissionUseCase: MyMissionUseCaseProtocol
    private let memberMissionUseCase: MemberMissionUseCaseProtocol
    private let memberMapper: MemberMapping
    private let missionMapper: MissionMapping

    // MARK: - Action & State

    enum Action {
        case viewDidLoad
        case didTapGroupOrganizationButton
        case didReceiveInvitationType(InvitationType)
        case didTapMissonCompleteButton(HomeItem)
        case didTapCompleteCancelButton
        case didTapMoreMyMissions
        case didSelectReceivedMember(Int)
        case didTapMoreMemberMissions
        case checkNotice
    }

    struct State {
        let user = BehaviorRelay<User?>(value: nil)
        let isShowGroupOrganizationView = PublishRelay<Bool>()
        let rankedMembers = PublishRelay<[HomeItem]>()
        let myMissions = BehaviorRelay<[HomeItem]>(value: [])
        let memberFilter = BehaviorRelay<[HomeItem]>(value: [])
        let memberMissionsForDisplay = PublishRelay<[HomeItem]>()
        let isShowSelectInvitationVC = PublishRelay<Void>()
        let isPushSendInvitationVC = PublishRelay<Void>()
        let isPushReceiveInvitationVC = PublishRelay<Void>()
        let isShowStampReceived = PublishRelay<(String, String)>()
        let completionCanceledMission = PublishRelay<String>()
        let isPushMyMissionVC = PublishRelay<Void>()
        let isPushMemberMissionVC = PublishRelay<Void>()
        let isPushNoticeListVC = PublishRelay<Void>()
    }

    // MARK: - Properties

    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()
    var memberCache = [String: Member]() // 멤버 정보 저장
    private var myMissions = [Mission]() // Firestore 상태 업데이트용 도메인 미션 캐시
    private var memberMissions = [Mission]()
    private var pendingStack: [Mission] = [] // 취소 가능한 미션 (3초 보관)

    // MARK: - Init

    init(rankingUseCase: RankingUseCaseProtocol,
         myMissionUseCase: MyMissionUseCaseProtocol,
         memberMissionUseCase: MemberMissionUseCaseProtocol,
         memberMapper: MemberMapper,
         missionMapper: MissionMapper,
    ) {
        self.rankingUseCase = rankingUseCase
        self.myMissionUseCase = myMissionUseCase
        self.memberMissionUseCase = memberMissionUseCase
        self.memberMapper = memberMapper
        self.missionMapper = missionMapper
        bind()
    }

    // MARK: - Bind

    private func bind() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .viewDidLoad:
                    owner.bindUser()
                case .didTapGroupOrganizationButton:
                    owner.handleSelectIvitation()
                case .didReceiveInvitationType(let type):
                    owner.handleInvitation(type: type)
                case .didTapMissonCompleteButton(let item):
                    let mission = item.myMission!
                    owner.handleMissionCompleteButtonTapped(missionID: mission.missionID)
                case .didTapCompleteCancelButton:
                    owner.handleCancelMissionComplete()
                case .didTapMoreMyMissions:
                    owner.state.isPushMyMissionVC.accept(())
                case .didSelectReceivedMember(let index):
                    owner.updateMemberMissions(index: index)
                case .didTapMoreMemberMissions:
                    owner.state.isPushMemberMissionVC.accept(())
                case .checkNotice:
                    owner.state.isPushNoticeListVC.accept(())
                }
            }
            .disposed(by: disposeBag)
    }

    /// user 정보 바인딩
    private func bindUser() {
        let currentUser = rankingUseCase.fetchCurrentUser()
            .compactMap { $0 }
            .do(onNext: { [weak self] user in
                self?.state.user.accept(user)
            })
            .share(replay: 1, scope: .whileConnected)

        bindRanking(ofUser: currentUser)
        bindMyMissions(ofUser: currentUser)
        bindMemberMissions(ofUser: currentUser)
    }

    private func bindRanking(ofUser currentUser: Observable<User>) {
        currentUser
          .flatMapLatest { [weak self] user -> Observable<[Member]> in
              guard let self = self else { return .empty() }
              return rankingUseCase.fetchRanking(ofGroup: user.groupID)
          }
          .subscribe(onNext: { [weak self] members in
              guard let self = self else { return }

              state.isShowGroupOrganizationView.accept(members.count == 1)

              // 멤버 정보 캐싱 후 매핑하여 랭킹 섹션에 아이템 렌더링하기
              memberCache = Dictionary(uniqueKeysWithValues: members.map { ($0.userID, $0) })
              let userID = state.user.value?.userID ?? ""
              let items = memberMapper
                  .map(members: members, userID: userID)
                  .map { HomeItem.member($0) }
              state.rankedMembers.accept(items)

              let memberNicknames = members
                  .filter { $0.userID != userID }
                  .map { HomeItem.memberFilter(title: $0.nickname) }
              state.memberFilter.accept([.memberFilter(title: "전체보기")] + memberNicknames)
          })
          .disposed(by: disposeBag)
    }

    private func bindMyMissions(ofUser currentUser: Observable<User>) {
        currentUser
          .flatMapLatest { [weak self] user -> Observable<[Mission]> in
              guard let self = self else { return .empty() }
              return self.myMissionUseCase.fetchAssignedMissions()
          }
          .subscribe(onNext: { [weak self] missions in
              guard let self = self else { return }
              self.myMissions = missions
              let items = self.missionMapper
                  .map(myMissions: missions, member: memberCache)
                  .map { HomeItem.myMission($0) }
              self.state.myMissions.accept(items)
              print("저장할 미션 데이터: \(missions)")
              
              // 위젯 데이터 저장 (mapForWidget 매핑 사용)
              let widgetMissions = self.missionMapper.map(widgetMissions: missions, member: self.memberCache)
              WidgetMissionManager.shared.save(missions: widgetMissions)
              WidgetCenter.shared.reloadAllTimelines()
              
              print("위젯용 미션 데이터 생성: \(widgetMissions.count)개")
              for mission in widgetMissions {
                  print("  - 제목: \(mission.title), 닉네임: \(mission.fromLabel), 날짜: \(mission.duration)")
              }
              
          })
          .disposed(by: disposeBag)
    }
    

    private func bindMemberMissions(ofUser currentUser: Observable<User>) {
        currentUser
          .flatMapLatest { [weak self] user -> Observable<[Mission]> in
              guard let self = self else { return .empty() }
              return self.memberMissionUseCase.fetchMissions(by: user.userID,ofGroup: user.groupID)
          }
          .subscribe(onNext: { [weak self] missions in
              guard let self = self else { return }
              self.memberMissions = missions
              let items = self.missionMapper
                  .map(memberMission: Array(missions.prefix(4)), member: memberCache)
                  .map { HomeItem.memberMission($0) }
              self.state.memberMissionsForDisplay.accept(items)
          })
          .disposed(by: disposeBag)
    }

    /// 멤버 닉네임으로 들어온 값이 "전체보기" 이면 전체, 값이 있으면 해당 멤버에게 전달한 미션만 필터링하여 최근 전달한 4개를 accept
    private func updateMemberMissions(index: Int) {
        let nickname = state.memberFilter.value[index].memberFilter!
        let memberID = memberCache.values.first(where: { $0.nickname == nickname })?.userID
        let filteredMissions = memberID != nil
            ? memberMissions.filter { $0.assignedTo == memberID }
            : memberMissions
        let first4 = Array(filteredMissions.prefix(4))
        let homeItems = missionMapper
            .map(memberMission: first4, member: memberCache)
            .map { HomeItem.memberMission($0) }
        state.memberMissionsForDisplay.accept(homeItems)
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
    /// myMissions에서 완료할 미션을 찾은 후 미션 완료 API를 호출하고 스티커 생성
    func handleMissionCompleteButtonTapped(missionID: String) {
        guard let mission = findMissionFromCache(missionID: missionID) else { return }

        let message = "'\(mission.title.truncatedTo10)' 미션을 완료했어요!"
        state.isShowStampReceived.accept((missionID, message))
        pendingStack.append(mission)

        /// 3초 후 pending중인 미션 제거
        Observable.just(())
            .delay(.seconds(3), scheduler: MainScheduler.instance)
            .bind(with: self, onNext: { owner, _ in
                guard !owner.pendingStack.isEmpty else { return }
                owner.pendingStack.removeFirst()
            })
            .disposed(by: disposeBag)

        // 미션 상태를 완료로 업데이트
        myMissionUseCase.updateMissionStatus(for: mission, to: .completed)
            .flatMap { [weak self] mission -> Observable<Void> in
                guard let self else { return .empty() }
                return myMissionUseCase.createSticker(mission: mission)
            }
            .subscribe()
            .disposed(by: disposeBag)
    }

    /// 토스트 “취소하기” 버튼 눌렀을 때 호출
    private func handleCancelMissionComplete() {
        guard !pendingStack.isEmpty else { return }
        let mission = pendingStack.removeLast()
        state.completionCanceledMission.accept(mission.missionID)

        /// 미션 상태를 진행중으로 롤백
        myMissionUseCase.updateMissionStatus(for: mission, to: .assigned)
            .flatMap { [weak self] mission -> Observable<Void> in
                guard let self else { return .empty() }
                return myMissionUseCase.deleteSticker(missionID: mission.missionID)
            }
            .subscribe()
            .disposed(by: disposeBag)
    }

    /// 도메인 미션 찾기
    private func findMissionFromCache(missionID: String) -> Mission? {
        guard let index = myMissions.firstIndex(where: { $0.missionID == missionID }) else { return nil }
        return myMissions[index]
    }
}
