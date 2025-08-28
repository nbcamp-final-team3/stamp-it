//
//  NoticeUseCase.swift
//  StampIt-Project
//
//  Created by daeun on 8/4/25.
//

import Foundation
import RxSwift

protocol NoticeUseCaseProtocol {
    func fetchNotices() -> Observable<[Notice]>
    func readNotice(_ noticeId: String) -> Observable<Void>
}
