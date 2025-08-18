//
//  NoticeManagerProtocol.swift
//  StampIt-Project
//
//  Created by 윤주형 study on 7/11/25.
//

import Foundation
import RxSwift

protocol NoticeManagerProtocol {
    func create(notice: DataNoticeFirestore) -> Observable<Void>
    func observeNotices(query: NoticeQuery) -> Observable<[DataNoticeFirestore]>
    func markAsRead(id: String) -> Observable<Void>
    func delete(id: String) -> Observable<Void>
}
