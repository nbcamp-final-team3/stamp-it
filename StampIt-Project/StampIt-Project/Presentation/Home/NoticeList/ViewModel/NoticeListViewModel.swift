//
//  NoticeListViewModel.swift
//  StampIt-Project
//
//  Created by daeun on 7/9/25.
//

import Foundation
import RxSwift
import RxRelay

final class NoticeListViewModel: ViewModelProtocol {
    // MARK: - Dependency

    private let useCase: NoticeUseCaseProtocol!

    // MARK: - Action & State

    enum Action {
        case navigateBack
        case load
        case selectNotice(Int)
    }

    struct State {
        var isNavigateBack = PublishRelay<Void>()
        var notices = BehaviorRelay<[HomeNotice]>(value: [])
        var noticeTarget = PublishRelay<NoticeCategory>()
    }

    // MARK: - Properties

    var noticeCache = [Notice]()
    let disposeBag = DisposeBag()
    let action = PublishRelay<Action>()
    var state = State()

    // MARK: - Init

    init(useCase: NoticeUseCaseProtocol) {
        self.useCase = useCase
        bind()
    }

    // MARK: - Bind

    private func bind() {
        action
            .subscribe(with: self) { owner, action in
                switch action {
                case .navigateBack:
                    owner.state.isNavigateBack.accept(())
                case .load:
                    owner.bindList()
                case .selectNotice(let row):
                    owner.handleSelection(of: row)
                }
            }
            .disposed(by: disposeBag)
    }

    private func bindList() {
        useCase.fetchNotices()
            .subscribe(onNext: { [weak self] notices in
                let notices: [Notice] = [
                    .init(noticeId: "123", title: "미션 받음", description: "설명", category: .newMission, createdAt: Date(), isRead: false),
                    .init(noticeId: "456", title: "미션 조르기", description: "설명", category: .missionRequest, createdAt: Date(), isRead: false),
                    .init(noticeId: "789", title: "멤버 변동", description: "설명", category: .member, createdAt: Date(), isRead: false)
                ]
                
                self?.noticeCache = notices
                
                let homeNotices = notices.map { notice in
                    HomeNotice(
                       noticeId: notice.noticeId,
                       title: notice.title,
                       description: notice.description,
                       date: notice.createdAt.toMonthDayStringKor(),
                       backgroundColor: notice.backgroundColor,
                       iconImage: notice.category.iconImage
                       )
                }
                self?.state.notices.accept(homeNotices)
            })
            .disposed(by: disposeBag)
    }
    
    private func handleSelection(of index: Int) {
        let target = noticeCache[index].category
        state.noticeTarget.accept(target)
    }
}
