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
    }

    struct State {
        var isNavigateBack = PublishRelay<Void>()
        var notices = BehaviorRelay<[HomeNotice]>(value: [])
    }

    // MARK: - Properties

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
                }
            }
            .disposed(by: disposeBag)
    }

    private func bindList() {
        useCase.fetchNotices()
            .subscribe(onNext: { [weak self] notices in
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
}
