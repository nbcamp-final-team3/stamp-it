//
//  NoticeUseCaseImpl.swift
//  StampIt-Project
//
//  Created by daeun on 8/4/25.
//

import Foundation
import RxSwift

final class NoticeUseCase: NoticeUseCaseProtocol {
    private let repository: NoticeRepositoryProtocol

    init(repository: NoticeRepositoryProtocol) {
        self.repository = repository
    }

    func fetchNotices() -> Observable<[Notice]> {
        repository.fetchNotices()
    }

    func readNotice(_ noticeId: String) -> RxSwift.Observable<Void> {
        repository.readNotice(noticeId)
    }
}
