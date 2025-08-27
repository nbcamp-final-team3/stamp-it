//
//  NoticeManagerProtocol.swift
//  StampIt-Project
//
//  Created by 윤주형 study on 7/11/25.
//

import Foundation
import RxSwift

protocol NoticeManagerProtocol {
    func create(notice: NoticeFirestore) -> Observable<Void>
    func observeNotices(query: NoticeQuery) -> Observable<[NoticeFirestore]>
    func markAsRead(id: String) -> Observable<Void>
    func delete(id: String) -> Observable<Void>
}
